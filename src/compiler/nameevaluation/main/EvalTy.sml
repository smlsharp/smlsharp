(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
(* the initial error code of this file : Ty-001 *)
structure EvalTy :
sig
  type tvarEnv
  val emptyTvarEnv : tvarEnv
  val genTvar : tvarEnv -> Absyn.tvar -> tvarEnv * IDCalc.tvar
  val genTvarList : tvarEnv -> Absyn.tvar list -> tvarEnv * IDCalc.tvar list
  val evalTy : tvarEnv -> NameEvalEnv.env -> Absyn.ty -> IDCalc.ty
  val evalTvar : Loc.loc -> tvarEnv -> Absyn.tvar -> IDCalc.tvar
  val evalFfity : tvarEnv -> NameEvalEnv.env -> PatternCalc.ffiTy -> IDCalc.ffiTy
  val emptyScopedTvars : IDCalc.scopedTvars
  val evalScopedTvars : 
      Loc.loc -> tvarEnv 
              -> NameEvalEnv.env
              -> PatternCalc.scopedTvars
              -> tvarEnv * IDCalc.kindedTvar list
  val evalDatatype :
      IDCalc.path -> NameEvalEnv.env
                   -> PatternCalc.datbind list * Loc.loc
                   -> NameEvalEnv.env * 'a list
end
=
struct
local
  structure I = IDCalc
  structure P = PatternCalc
  structure V = NameEvalEnv
  structure N = NormalizeTy
  structure BV = BuiltinEnv
  structure U = NameEvalUtils
  structure EU = UserErrorUtils
  structure E = NameEvalError
  structure A = Absyn
  structure L = SetLiftedTys
  fun bug s = Control.Bug ("NameEval(EvalTy): " ^ s)
in
  type tvarEnv = I.tvar SEnv.map
  val emptyTvarEnv = SEnv.empty : tvarEnv

  fun genTvar (tvarEnv:tvarEnv) {name, eq} : tvarEnv * I.tvar =
      let
        val id = TvarID.generate()
        val tvar = {name=name, eq=eq,id=id,lifted=false}
      in
        (SEnv.insert(tvarEnv, name, tvar), tvar)
      end

  fun genTvarList (tvarEnv:tvarEnv) tvarList : tvarEnv * I.tvar list =
      U.evalTailList {env=tvarEnv, eval=genTvar} tvarList

  (* type variable evaluators *)
  fun evalTvar loc (tvarEnv:tvarEnv) {name, eq} : I.tvar =
      case SEnv.find(tvarEnv, name) of
        SOME tvar => tvar
      | NONE =>
        (EU.enqueueError
           (loc, E.TvarNotFound("Ty-010",{name = name}));
         {name=name, eq=eq, id=TvarID.generate(), lifted=false})

  (* type evaluators, which return a type etc and liftedtys *)
  fun evalTy (tvarEnv:tvarEnv) (env:V.env) (ty:A.ty) : I.ty  =
    case ty of
      A.TYWILD loc => I.TYWILD
    | A.TYID (tvar, loc) => I.TYVAR (evalTvar loc tvarEnv tvar)
    | A.TYRECORD (nil, loc) => BV.unitTy
    | A.TYRECORD (tyFields, loc) =>
      (EU.checkNameDuplication
         #1 tyFields loc 
         (fn s => E.DuplicateRecordLabelInRawType("Ty-020",s));
       I.TYRECORD
         (foldl
            (fn ((l,ty), fields) =>
                LabelEnv.insert(fields, l, evalTy tvarEnv env ty))
            LabelEnv.empty
            tyFields
         )
      )
    | A.TYCONSTRUCT (tyList, path, loc) =>
      let
        exception Arity
      in
        let
          fun makeTy tfun =
              let
                val tyList = map (evalTy tvarEnv env) tyList
                val _ = if length tyList = I.tfunArity tfun then ()
                        else raise Arity
              in
                case I.pruneTfun tfun of 
                  I.TFUN_DEF {iseq,formals,realizerTy} =>
                  let
                    val reduceEnv =
                        foldr
                          (fn ((tvar, ty), tvarEnv) =>
                              TvarMap.insert(tvarEnv, tvar, ty))
                          TvarMap.empty
                          (ListPair.zip(formals, tyList))
                    val newTy = N.reduceTy reduceEnv realizerTy
                  in
                    newTy
                  end
                | I.TFUN_VAR _ =>
                  I.TYCONSTRUCT {typ={path=path, tfun=tfun}, args=tyList}
              end
        in
          case V.lookupTstr env path handle e => raise e
           of
            V.TSTR tfun => makeTy tfun
          | V.TSTR_DTY {tfun, varE, formals, conSpec} => makeTy tfun
        end
        handle Arity =>
               (EU.enqueueError (loc, E.TypArity("Ty-030",{longid = path}));
                I.TYERROR
               )
             | V.LookupTstr =>
               (EU.enqueueError (loc, E.TypNotFound("Ty-040",{longid = path}));
                I.TYERROR
               )

      end
    | A.TYTUPLE(nil, loc) => BV.unitTy
    | A.TYTUPLE(tyList, loc) =>
      evalTy tvarEnv env (A.TYRECORD (Utils.listToTuple tyList, loc))
    | A.TYFUN(ty1,ty2, loc) =>
      I.TYFUNM([evalTy tvarEnv env ty1], evalTy tvarEnv env ty2)
    | A.TYPOLY (kindedTvarList, ty, loc) =>
      let
        val (tvarEnv, kindedTvarList) =
            evalKindedTvarList loc tvarEnv env kindedTvarList
        val ty = evalTy tvarEnv env ty
      in
        I.TYPOLY (kindedTvarList,ty)
      end
  and evalTvarKind (tvarEnv:tvarEnv) (env:V.env) kind : I.tvarKind  =
      case kind of
        A.UNIV => I.UNIV
      | A.REC (tyFields, loc) =>
        (EU.checkNameDuplication
           #1 tyFields loc
           (fn s => E.DuplicateRecordLabelInKind("Ty-050",s));
         I.REC 
           (foldl
              (fn ((l,ty), fields) =>
                  LabelEnv.insert(fields, l, evalTy tvarEnv env ty)
              )
              LabelEnv.empty
              tyFields
           )
        )
  and evalKindedTvarList loc (tvarEnv:tvarEnv) (env:V.env) tvarKindList
      : tvarEnv * I.kindedTvar list =
      let
        fun evalTvar tvarEnv (tvar, kind)  =
            let
              val (tvarEnv, tvar) = genTvar tvarEnv tvar
            in
              (tvarEnv, (tvar, kind))
            end
        val (tvarEnv, tvarKindList) =
            U.evalTailList {env=tvarEnv,eval=evalTvar} tvarKindList
        val tvarKindList =
            map (fn (tvar, kind) => (tvar, evalTvarKind tvarEnv env kind))
                tvarKindList
      in
        (tvarEnv, tvarKindList)
      end

  fun ffiTyToAbsynTy ffiTy =
      case ffiTy of
        P.FFIFUNTY (attributes, [argTy], [retTy], loc) =>
        A.TYFUN (ffiTyToAbsynTy argTy, ffiTyToAbsynTy retTy, loc)
      | P.FFIFUNTY (attributes, argTys, retTys, loc) =>
        (EU.enqueueError (loc, E.FFIFunTyIsNotAllowedHere("Ty-060", ffiTy));
         A.TYTUPLE (nil, loc))  (* dummy *)
      | P.FFITYVAR (tvar, loc) =>
        A.TYID (tvar, loc)
      | P.FFIRECORDTY (fields, loc) =>
        A.TYRECORD (map (fn (label, ty) => (label, ffiTyToAbsynTy ty)) fields,
                    loc)
      | P.FFICONTY (argTyList, path, loc) =>
        A.TYCONSTRUCT (map ffiTyToAbsynTy argTyList, path, loc)

  fun tyToFfiTy subst (ty, loc) =
      case ty of
        I.TYWILD => I.FFIBASETY (ty, loc)
      | I.TYERROR => I.FFIBASETY (ty, loc)
      | I.TYCONSTRUCT _ => I.FFIBASETY (ty, loc)
      | I.TYFUNM _ => I.FFIBASETY (ty, loc)
      | I.TYPOLY _ => I.FFIBASETY (ty, loc)
      | I.INFERREDTY _ => I.FFIBASETY (ty, loc) (* FIXME *)
      | I.TYVAR tvar =>
        (
          case TvarMap.find (subst, tvar) of
            NONE => I.FFIBASETY (ty, loc)
          | SOME ffity => ffity
        )
      | I.TYRECORD fields =>
        let
          fun isTuple (i, nil) = true
            | isTuple (i, (k,v)::t) =
              Int.toString i = k andalso isTuple (i + 1,t)
          val fields = LabelEnv.listItemsi fields
        in
          if isTuple (1, fields)
          then I.FFIRECORDTY
                 (map (fn (label, ty) => (label, tyToFfiTy subst (ty, loc)))
                      fields, loc)
          else I.FFIBASETY (ty, loc)
        end

  fun evalFfity (tvarEnv:tvarEnv) (env:V.env) ffiTy =
      let
        val evalFfity = evalFfity tvarEnv env
      in
        case ffiTy of
          P.FFIFUNTY (ffiAttributesOption, argTys, retTys, loc) =>
          I.FFIFUNTY (ffiAttributesOption,
                      map evalFfity argTys,
                      map evalFfity retTys,
                      loc)
        | P.FFITYVAR (tvar, loc) =>
          I.FFIBASETY (evalTy tvarEnv env (ffiTyToAbsynTy ffiTy), loc)
        | P.FFIRECORDTY (stringFfityList, loc) =>
          I.FFIRECORDTY
            (map (fn (l, ty) => (l, evalFfity ty)) stringFfityList,
             loc)
        | P.FFICONTY (argTyList, typath, loc) =>
          (
            case V.lookupTstr env typath handle e => raise e
             of
              V.TSTR (I.TFUN_DEF {iseq, formals, realizerTy}) =>
              let
                val argTyList = map evalFfity argTyList
                val subst =
                    List.foldl 
                      (fn ((key, item), m) => TvarMap.insert (m, key, item)) TvarMap.empty 
                      (ListPair.zipEq (formals, argTyList)
                       handle UnqeualLengths =>
                              raise bug "FIXME: tfun arity mismatch")
              in
                tyToFfiTy subst (realizerTy, loc)
              end
            | _ => I.FFIBASETY (evalTy tvarEnv env (ffiTyToAbsynTy ffiTy), loc)
          )
          handle V.LookupTstr =>
                 (EU.enqueueError
                    (loc, E.TypNotFound("Ty-070",{longid = typath}));
                  I.FFIBASETY (I.TYERROR, loc))
      end

  val emptyScopedTvars = nil : I.scopedTvars
  fun evalScopedTvars loc (tvarEnv:tvarEnv) (env:V.env) (tvars:P.scopedTvars) =
      evalKindedTvarList loc tvarEnv env tvars
 
  fun evalDatatype (path:I.path) (env:V.env) (datbindList, loc) =
      let
        val _ = EU.checkNameDuplication
                  (fn {tyvars, tycon, conbind} => tycon)
                  datbindList
                  loc
                  (fn s => E.DuplicateTypInDty("Ty-080",s))
        val _ = EU.checkNameDuplication
                  (fn {vid=string, ty=tyOption} => string)
                  (foldl
                     (fn ({tyvars, tycon, conbind}, allCons) =>
                         allCons@conbind)
                     nil
                     datbindList)
                  loc
                  (fn s => E.DuplicateConNameInDty("Ty-090",s))
        val (newEnv, datbindListRev) =
            foldl
              (fn ({tyvars=tvarList,tycon=string,conbind},
                   (newEnv, datbindListRev)) =>
                  let
                    val _ = EU.checkNameDuplication
                              (fn {name, eq} => name)
                              tvarList
                              loc
                              (fn s => E.DuplicateTypParms("Ty-100",s))
                    val (tvarEnv, tvarList)=
                        genTvarList emptyTvarEnv tvarList
                    val id = TypID.generate()
                    val iseqRef = ref true
                    val tfv =
                        I.mkTfv(I.TFV_SPEC{id=id,iseq=true,formals=tvarList})
                    val tfun = I.TFUN_VAR tfv
                    val newEnv =V.rebindTstr(newEnv,string,V.TSTR tfun)
                    val datbindListRev =
                        {name=string,
                         id=id,
                         tfv=tfv,
                         tfun=tfun,
                         iseqRef=iseqRef,
                         args=tvarList,
                         tvarEnv=tvarEnv,
                         conbind=conbind}
                        :: datbindListRev
                  in
                    (newEnv, datbindListRev)
                  end
              )
              (V.emptyEnv, nil)
              datbindList
        val evalEnv = V.envWithEnv (env, newEnv)
        val datbindList =
            foldl
              (fn ({name, id, tfv, tfun, iseqRef, args, tvarEnv, conbind},
                   datbindList) =>
                  let
                    val returnTy =
                        I.TYCONSTRUCT
                          {typ={path=path@[name],tfun=tfun},
                           args= map (fn tv=>I.TYVAR tv) args
                          }
                    val (conVarE, conSpec, conbindRev) =
                        foldl
                          (fn ({vid=string,ty=tyOption},
                               (conVarE,conSpec,conbindRev)) =>
                              let
                                val conId = ConID.generate()
                                val conInfo = {path=path@[string], id=conId}
                                val (tyOption, conTy) =
                                    case tyOption of
                                      NONE => 
                                      (NONE, 
                                       case args of
                                         nil => returnTy
                                       | _ => I.TYPOLY
                                              (
                                               map (fn tv =>(tv, I.UNIV)) args,
                                               returnTy
                                              )
                                      )
                                    | SOME ty =>
                                      let
                                        val ty = evalTy tvarEnv evalEnv ty
                                      in
                                        (SOME ty,
                                         case args of
                                           nil => I.TYFUNM([ty], returnTy)
                                         | _ => 
                                           I.TYPOLY
                                             (
                                              map (fn tv =>(tv, I.UNIV)) args,
                                              I.TYFUNM([ty], returnTy)
                                             )
                                        )
                                      end
                                val idstatus = I.IDCON {id=conId, ty=conTy}
                              in
                                (SEnv.insert(conVarE, string, idstatus),
                                 SEnv.insert(conSpec, string, tyOption),
                                 {datacon=conInfo,tyOpt=tyOption}
                                 :: conbindRev
                                )
                              end
                          )
                          (SEnv.empty,SEnv.empty,nil)
                          conbind
                  in
                    {name=name,
                     id=id,
                     tfv=tfv,
                     conVarE=conVarE,
                     conSpec=conSpec,
                     iseqRef=iseqRef,
                     args=args,
                     conbind=List.rev conbindRev}
                    :: datbindList
                  end)
              nil
              datbindListRev
        val _ = N.setEq 
                  (map 
                     (fn {id, args, conSpec, iseqRef,...} =>
                         {id=id, args=args, conSpec=conSpec, iseqRef=iseqRef})
                     datbindList
                  )
        val newEnv =
            foldr
              (fn ({name,id,tfv,conVarE,conSpec,iseqRef,args,conbind},
                   newEnv) =>
                  let
                    val runtimeTy = U.runtimeTyOfConspec conSpec
                    val tfunkind =
                        I.TFUN_DTY
                          {id=id,
                           iseq = !iseqRef,
                           conSpec=conSpec,
                           originalPath=path@[name],
			   runtimeTy = runtimeTy,
                           formals=args,
                           liftedTys=I.emptyLiftedTys,
                           dtyKind=I.DTY
                          }
(*
                        I.TFV_DTY
                          {id=id,
                           iseq = !iseqRef,
                           conSpec=conSpec,
                           formals=args,
                           liftedTys=I.emptyLiftedTys
                          }
*)
                    val _ = tfv := tfunkind
                    val newEnv = 
                        V.rebindTstr(newEnv,
                                     name,
                                     V.TSTR_DTY {tfun=I.TFUN_VAR tfv,
                                                 varE=conVarE,
                                                 formals=args,
                                                 conSpec=conSpec
                                                }
                                    )
                    val newEnv = V.envWithVarE(newEnv, conVarE)
                  in
                    newEnv
                  end
              )
              V.emptyEnv
              datbindList
        val pathTfvListList = L.setLiftedTysEnv newEnv
      in
        (newEnv, nil)
      end
end
end
