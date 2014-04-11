(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
(* the initial error code of this file : Ty-001 *)
structure EvalTy =
struct
local
  structure I = IDCalc
  structure P = PatternCalc
  structure V = NameEvalEnv
  structure N = NormalizeTy
  structure BT = BuiltinTypes
  structure U = NameEvalUtils
  structure EU = UserErrorUtils
  structure E = NameEvalError
  structure A = Absyn
  structure L = SetLiftedTys
  structure PI = PatternCalcInterface
  fun bug s = Bug.Bug ("NameEval(EvalTy): " ^ s)
in
  type tvarEnv = I.tvar SymbolEnv.map
  val emptyTvarEnv = SymbolEnv.empty : tvarEnv

  fun genTvar (tvarEnv:tvarEnv) {symbol, eq} : tvarEnv * I.tvar =
      let
        val id = TvarID.generate()
        val tvar = {symbol=symbol, eq=eq, id=id, lifted=false}
      in
        (SymbolEnv.insert(tvarEnv, symbol, tvar), tvar)
      end

  fun genTvarList (tvarEnv:tvarEnv) tvarList : tvarEnv * I.tvar list =
      U.evalTailList {env=tvarEnv, eval=genTvar} tvarList

  (* type variable evaluators *)
  fun evalTvar (tvarEnv:tvarEnv) {symbol, eq} : I.tvar =
      case SymbolEnv.find(tvarEnv, symbol) of
        SOME tvar => tvar
      | NONE =>
        (EU.enqueueError
           (Symbol.symbolToLoc symbol, E.TvarNotFound("Ty-010",{symbol = symbol}));
         {symbol=symbol, eq=eq, id=TvarID.generate(), lifted=false})

  fun checkCyclicKind tvarKindList =
      let
        val kindEnv =
            foldl 
            (fn ((tvar, kind), tvarMap) => TvarMap.insert(tvarMap, tvar, kind))
            TvarMap.empty
            tvarKindList
        fun EFTVkind (kind, tvarSet) =
            case kind of
              I.UNIV => tvarSet
            | I.REC fields =>
              LabelEnv.foldl
              (fn (ty, tvarSet) => EFTVty (ty, tvarSet))
              tvarSet
              fields
        and EFTVty (ty, tvarSet) =
            case ty of
              I.TYWILD => tvarSet
            | I.TYERROR => tvarSet
            | I.TYVAR tvar => 
              if TvarSet.member(tvarSet, tvar) then tvarSet
              else 
                (case TvarMap.find(kindEnv, tvar) of
                   NONE => TvarSet.add(tvarSet, tvar)
                 | SOME kind => 
                   EFTVkind(kind, TvarSet.add(tvarSet, tvar))
                )
            | I.TYRECORD fields =>
              LabelEnv.foldl
              (fn (ty, tvarSet) => EFTVty (ty, tvarSet))
              tvarSet
              fields
            | I.TYCONSTRUCT {tfun, args} =>
              foldl
              (fn (ty, tvarSet) => EFTVty (ty, tvarSet))
              tvarSet
              args
            | I.TYFUNM (tyList, ty) =>
              foldl
              (fn (ty, tvarSet) => EFTVty (ty, tvarSet))
              (EFTVty (ty, tvarSet))
              tyList
            | I.TYPOLY (kindedTvarList,ty) =>
              let
                val boundTvars =
                    foldl
                    (fn ((tvar, kind), boundTvars) =>
                        TvarSet.add(boundTvars, tvar))
                    TvarSet.empty
                    kindedTvarList
              in
                TvarSet.difference(EFTVty (ty,tvarSet), boundTvars)
              end
            | I.INFERREDTY typesTy => tvarSet
        fun checkTvarKind ((tvar, kind), cycleList) = 
            let
              val eftv = 
                  case TvarMap.find(kindEnv, tvar) of
                    NONE => TvarSet.empty
                  | SOME kind => EFTVkind(kind, TvarSet.empty)
            in
              if TvarSet.member(eftv, tvar) then tvar::cycleList
              else cycleList
            end
      in
        foldr checkTvarKind nil tvarKindList
      end


  (* type evaluators, which return a type etc and liftedtys *)
  fun evalTy (tvarEnv:tvarEnv) (env:V.env) (ty:A.ty) : I.ty  =
    case ty of
      A.TYWILD loc => I.TYWILD
    | A.TYID (tvar, loc) => I.TYVAR (evalTvar tvarEnv tvar)
    | A.TYRECORD (nil, loc) => BT.unitITy
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
                  I.TFUN_DEF {longsymbol, iseq,formals,realizerTy} =>
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
                  I.TYCONSTRUCT {tfun=tfun, args=tyList}
              end
        in
          case V.lookupTstr env path handle e => raise e
           of
            V.TSTR tfun => makeTy tfun
          | V.TSTR_DTY {tfun, varE, formals, conSpec} => makeTy tfun
        end
        handle Arity =>
               (EU.enqueueError (loc, E.TypArity("Ty-030",{longsymbol =  path}));
                I.TYERROR
               )
             | V.LookupTstr =>
               (EU.enqueueError (loc, E.TypNotFound("Ty-040",{longsymbol = path}));
                I.TYERROR
               )

      end
    | A.TYTUPLE(nil, loc) => BT.unitITy
    | A.TYTUPLE(tyList, loc) =>
      evalTy tvarEnv env (A.TYRECORD (Utils.listToTuple tyList, loc))
    | A.TYFUN(ty1,ty2, loc) =>
      I.TYFUNM([evalTy tvarEnv env ty1], evalTy tvarEnv env ty2)
    | A.TYPOLY (kindedTvarList, ty, loc) =>
      let
        val (tvarEnv, kindedTvarList) =
            evalKindedTvarList tvarEnv env kindedTvarList
(*
        val cyclicTvars = checkCyclicKind kindedTvarList 
        fun tvarLoc {symbol, id, eq, lifted} = Symbol.symbolToLoc symbol
        val kindedTvarList =
            case cyclicTvars of
              nil => kindedTvarList
            | tvar1 :: rest => 
              let
                val tvarsLoc =
                    foldl
                    (fn (loc1, loc) => Loc.mergeLoc (loc1, loc))
                    (tvarLoc tvar1)
                    (map tvarLoc rest)
              in
                (EU.enqueueError
                 (tvarsLoc, 
                  E.CyclicKind("Ty-045", {tvarList = cyclicTvars}));
                 map (fn (tvar, kind) => (tvar, I.UNIV)) kindedTvarList)
*)
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
  and evalKindedTvarList (tvarEnv:tvarEnv) (env:V.env) tvarKindList
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
        val cyclicTvars = checkCyclicKind tvarKindList
        fun tvarLoc {symbol, id, eq, lifted} = Symbol.symbolToLoc symbol
        val tvarKindList =
            case cyclicTvars of
              nil => tvarKindList
            | tvar1 :: rest => 
              let
                val tvarsLoc =
                    foldl
                    (fn (loc1, loc) => Loc.mergeLocs (loc1, loc))
                    (tvarLoc tvar1)
                    (map tvarLoc rest)
              in
                (EU.enqueueError
                 (tvarsLoc, 
                  E.CyclicKind("Ty-045", {tvarList = cyclicTvars}));
                 map (fn (tvar, kind) => (tvar, I.UNIV)) tvarKindList)
              end
(*
        val tvarKindList =
            case cyclicTvars of
              nil => tvarKindList
            | _ => 
              (EU.enqueueError
                 (loc, 
                  E.CyclicKind("Ty-045", {stringList = cyclicTvars}));
               map (fn (tvar, kind) => (tvar, I.UNIV)) tvarKindList)
*)
      in
        (tvarEnv, tvarKindList)
      end

  fun compatRuntimeTy {absTy, implTy} = 
      case (absTy, implTy) of 
        (I.LIFTEDty {id=id1,...}, I.LIFTEDty {id=id2,...}) =>
        TvarID.eq(id1,id2) 
      | (I.BUILTINty bty1, I.BUILTINty bty2) => 
        BuiltinTypeNames.compatTy {absTy=bty1, implTy=bty2}
      | _ => false

  exception EvalRuntimeTy
  fun evalRuntimeTy tvarEnv evalEnv runtimeTy =
      case runtimeTy of
        PI.BUILTINty ty => I.BUILTINty ty
      | PI.LIFTEDty longsymbol => 
        let
          val loc = Symbol.longsymbolToLoc longsymbol
          val aty = A.TYCONSTRUCT(nil, longsymbol, loc)
          val ity = evalTy tvarEnv evalEnv aty
        in
          case ity of
            I.TYVAR (tvar as {lifted,...}) => 
            if lifted then I.LIFTEDty tvar
            else raise EvalRuntimeTy
          | _ => 
            (case I.runtimeTyOfIty ity of
               SOME ty =>  ty
             | NONE => raise EvalRuntimeTy
            )
        end

  fun ffiTyToAbsynTy ffiTy =
      case ffiTy of
        P.FFIFUNTY (attributes, [argTy], NONE, [retTy], loc) =>
        A.TYFUN (ffiTyToAbsynTy argTy, ffiTyToAbsynTy retTy, loc)
      | P.FFIFUNTY (attributes, argTys, varargTys, retTys, loc) =>
        (EU.enqueueError (loc, E.FFIFunTyIsNotAllowedHere("Ty-060", ffiTy));
         A.TYTUPLE (nil, loc))  (* dummy *)
      | P.FFITYVAR (tvar, loc) =>
        A.TYID (tvar, loc)
      | P.FFIRECORDTY (fields, loc) =>
        A.TYRECORD (map (fn (label, ty) => (label, ffiTyToAbsynTy ty)) fields,
                    loc)
      | P.FFICONTY (argTyList, longsymbol, loc) =>
        A.TYCONSTRUCT (map ffiTyToAbsynTy argTyList, longsymbol, loc)

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
          P.FFIFUNTY (ffiAttributesOption, argTys, varTys, retTys, loc) =>
          I.FFIFUNTY (ffiAttributesOption,
                      map evalFfity argTys,
                      Option.map (map evalFfity) varTys,
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
              V.TSTR (I.TFUN_DEF {longsymbol, iseq, formals, realizerTy}) =>
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
                    (loc, E.TypNotFound("Ty-070",{longsymbol = typath}));
                  I.FFIBASETY (I.TYERROR, loc))
      end

  val emptyScopedTvars = nil : I.scopedTvars
  fun evalScopedTvars (tvarEnv:tvarEnv) (env:V.env) (tvars:P.scopedTvars) =
      evalKindedTvarList tvarEnv env tvars
 
  fun evalDatatype 
        (path:Symbol.symbol list) 
        (env:V.env) 
        (datbindList:PatternCalc.datbind list, loc:Loc.loc) 
       : NameEvalEnv.env * IDCalc.icdecl list
       =
      let
        val _ = EU.checkSymbolDuplication
                  (fn {tyvars, symbol, conbind} => symbol)
                  datbindList
                  (fn s => E.DuplicateTypInDty("Ty-080",s))
        val _ = EU.checkSymbolDuplication
                  (fn {symbol, ty=tyOption} => symbol)
                  (foldl
                     (fn ({tyvars, symbol, conbind}, allCons) =>
                         allCons@conbind)
                     nil
                     datbindList)
                  (fn s => E.DuplicateConNameInDty("Ty-090",s))
        val (newEnv, datbindListRev) =
            foldl
              (fn ({tyvars=tvarList,symbol,conbind},
                   (newEnv, datbindListRev)) =>
                  let
                    val _ = EU.checkSymbolDuplication
                              (fn {symbol, eq} => symbol)
                              tvarList
                              (fn s => E.DuplicateTypParms("Ty-100",s))
                    val (tvarEnv, tvarList)=
                        genTvarList emptyTvarEnv tvarList
                    val id = TypID.generate()
                    val iseqRef = ref true
                    val longsymbol = Symbol.prefixPath (path , symbol)
                    val tfv =
                        I.mkTfv(I.TFV_SPEC{longsymbol= longsymbol, id=id,iseq=true,formals=tvarList})
                    val tfun = I.TFUN_VAR tfv
                    val newEnv =V.insertTstr(newEnv, symbol, V.TSTR tfun)
                    val datbindListRev =
                        {name= symbol,
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
                          {tfun=tfun,
                           args= map (fn tv=>I.TYVAR tv) args
                          }
                    val (conVarE, conSpec, conIDSet) =
                        foldl
                          (fn ({symbol,ty=tyOption},
                               (conVarE,conSpec, conIDSet)) =>
                              let
                                val longsymbol = Symbol.prefixPath(path, symbol)
                                val conId = ConID.generate()
                                val conIDSet = ConID.Set.add (conIDSet, conId)
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
                                val conInfo = {id=conId, longsymbol=longsymbol, ty=conTy}
                                val _ = V.conEnvAdd (conId, conInfo)
                                val idstatus = I.IDCON conInfo
                              in
                                (SymbolEnv.insert(conVarE, symbol, idstatus),
                                 SymbolEnv.insert(conSpec, symbol, tyOption),
                                 conIDSet
                                )
                              end
                          )
                          (SymbolEnv.empty,SymbolEnv.empty,ConID.Set.empty)
                          conbind
                  in
                    {name=name,
                     id=id,
                     tfv=tfv,
                     conVarE=conVarE,
                     conSpec=conSpec,
                     conIDSet=conIDSet,
                     iseqRef=iseqRef,
                     args=args}
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
              (fn ({name,id,tfv,conVarE,conSpec,conIDSet,iseqRef,args},
                   newEnv) =>
                  let
                    val runtimeTy = BuiltinTypes.runtimeTyOfConspec conSpec
                    val tfunkind =
                        I.TFUN_DTY
                          {id=id,
                           iseq = !iseqRef,
                           conSpec=conSpec,
                           conIDSet=conIDSet,
                           longsymbol= Symbol.prefixPath (path , name),
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
                    val newEnv = V.bindEnvWithVarE(newEnv, conVarE)
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
