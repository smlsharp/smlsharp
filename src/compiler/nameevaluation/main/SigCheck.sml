(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
structure SigCheck : 
sig
  exception SIGCHECK
  datatype mode = Opaque | Trans
  type sigCheckParam =
       {mode:mode,
        loc:Loc.loc,
        strPath:string list,
        strEnv:NameEvalEnv.env,
        specEnv:NameEvalEnv.env}
  type sigCheckResult = NameEvalEnv.env * IDCalc.icdecl list 
  val sigCheck : sigCheckParam -> sigCheckResult
  val refreshEnv : TypID.Set.set *  Subst.exnIdSubst -> NameEvalEnv.env 
                   -> (Subst.tfvSubst * Subst.conIdSubst) * NameEvalEnv.env
end
=
struct
local
  structure I = IDCalc
  structure BV = BuiltinEnv
  structure Ty = EvalTy
  structure ITy = EvalIty
  structure V = NameEvalEnv
  structure BV = BuiltinEnv
  structure L = SetLiftedTys
  structure S = Subst
  structure TF = TfunVars
  structure P = PatternCalc
  structure PI = PatternCalcInterface
  structure U = NameEvalUtils
  structure EU = UserErrorUtils
  structure E = NameEvalError
  structure A = Absyn
  structure N = NormalizeTy
  structure Sig = EvalSig
  structure FU = FunctorUtils
  fun bug s = Control.Bug ("SigCheck: " ^ s)
in
  exception SIGCHECK
  datatype mode = Opaque | Trans
  type sigCheckParam =
       {mode:mode,loc:Loc.loc,strPath:string list,strEnv:V.env,specEnv:V.env}
  type sigCheckResult = V.env * I.icdecl list 
  fun sigCheck (param as {mode, loc, ...} : sigCheckParam) : sigCheckResult =
    let
      val revealKey = RevealID.generate() (* for each sigCheck instance *)
      fun instantiateEnv path (specEnv, strEnv) =
        let
          fun instantiateTstr name (specTstr, strTstr) =
              let
                val tfun = 
                    case specTstr of
                      V.TSTR tfun => tfun
                    | V.TSTR_DTY {tfun, ...} => tfun
              in
                case I.derefTfun tfun of
                  I.TFUN_DEF _ => ()
                | I.TFUN_VAR (tfv as (ref (I.REALIZED _))) => 
                  raise bug "REALIZED"
                | I.TFUN_VAR (tfv as (ref (I.INSTANTIATED _))) => ()
                | I.TFUN_VAR (tfv as (ref (I.FUN_DTY _))) => ()
                | I.TFUN_VAR (tfv as (ref (I.TFUN_DTY _))) => ()
                | I.TFUN_VAR (tfv as (ref (tfunkind as I.TFV_SPEC _))) =>
                  (case strTstr of
                     V.TSTR tfun => 
                     tfv := I.INSTANTIATED {tfunkind=tfunkind, tfun=tfun}
                   | V.TSTR_DTY {tfun, ...} =>
                     tfv := I.INSTANTIATED {tfunkind=tfunkind, tfun=tfun}
                  )
                | I.TFUN_VAR (tfv as (ref (tfunkind as I.TFV_DTY _))) =>
                  (case strTstr of
                     V.TSTR tfun => 
                     tfv := I.INSTANTIATED {tfunkind=tfunkind, tfun=tfun}
                   | V.TSTR_DTY {tfun, ...} =>
                     tfv := I.INSTANTIATED {tfunkind=tfunkind, tfun=tfun}
                  )
              end                                           
          fun instantiateTyE (specTyE, strTyE) =
              SEnv.appi
                (fn (string, specTstr) =>
                    case SEnv.find (strTyE, string) of
                      NONE => ()
                    | SOME strTstr => 
                      instantiateTstr string (specTstr, strTstr)
                )
                specTyE
          fun instantiateStrE (V.STR specEnvMap, V.STR strEnvMap) =
              SEnv.appi
              (fn (name, {env=specEnv, strKind=_}) =>
                  case SEnv.find(strEnvMap, name) of
                    NONE => () (* error will be checked in checkStrE *)
                  | SOME {env=strEnv, strKind=_} =>
                    instantiateEnv (path@[name]) (specEnv, strEnv)
              )
              specEnvMap
          val V.ENV{tyE=specTyE, strE=specStrE, ...} = specEnv
          val V.ENV{tyE=strTyE, strE=strStrE, ...} = strEnv
        in
          instantiateTyE (specTyE, strTyE);
          instantiateStrE (specStrE, strStrE)
        end

      fun checkEnv path (specEnv, strEnv) : sigCheckResult =
        let
          val V.ENV{varE=specVarE,tyE=specTyE, strE=specStrE} = specEnv
          val V.ENV{varE=strVarE,tyE=strTyE, strE=strStrE} = strEnv
          fun checkTfun name (specTfun, strTfun) =
              let
                val specTfun =
                    I.pruneTfun(N.reduceTfun(I.pruneTfun specTfun))
                val strTfun =
                    I.derefTfun (N.reduceTfun (I.pruneTfun strTfun))
              in
                case (specTfun, strTfun) of
                  (I.TFUN_DEF {formals=specFormals, realizerTy=specTy,...},
                   I.TFUN_DEF {formals=strFormals, realizerTy=strTy,...}) =>
                  if List.length specFormals <> List.length strFormals then
                     EU.enqueueError
                       (loc,E.SIGArity("200",{longid=path@[name]}))
                  else if N.eqTydef N.emptyTypIdEquiv ((specFormals,specTy),(strFormals,strTy))
                  then ()
                  else
                    (
                     EU.enqueueError
                       (loc,E.SIGDtyMismatch
                              ("210",{longid=path@[name ^ "(1)"]}))
                    )
                | (I.TFUN_VAR (ref (I.TFUN_DTY {id=id1,...})),
                   I.TFUN_VAR (ref (I.TFUN_DTY {id=id2,...}))) =>
                  if TypID.eq(id1,id2) then ()
                  else 
                    (
                     EU.enqueueError
                       (loc,
                        E.SIGDtyMismatch("220",{longid=path@[name ^ "(2)"]}))
                    )
                | _ => 
                  (
                   EU.enqueueError
                     (loc,E.SIGDtyMismatch("230",{longid=path@[name ^ "(3)"]}))
                  )
              end

          fun checkTstr name (specTstr, strTstr) =
              let
                fun checkVarE varE =
                    SEnv.appi
                      (fn (name, idstatus) => 
                          case SEnv.find(strVarE, name) of
                            NONE => 
                            EU.enqueueError
                              (loc,
                               E.SIGConNotFound
                                 ("240",{longid=path@[name ^ ":(1)"]}))
                          | SOME strIdstatus =>
                            (case (idstatus, strIdstatus) of
                               (I.IDCON {id=conid1,ty=ty1},
                                I.IDCON {id=conid2,ty=ty2}) =>
                               if ConID.eq(conid1, conid2) then ()
                               else
                                 (
                                  EU.enqueueError
                                    (loc,
                                     E.SIGConNotFound
                                       ("250",{longid=path@[name ^ ":(2)"]}))
                                 )
                             | (I.IDSPECCON, I.IDCON _) => ()
                             | (I.IDCON _, _) => 
                               EU.enqueueError
                                 (loc,
                                  E.SIGConNotFound
                                    ("260",{longid=path@[name ^ ":(3)"]}))
                             | _ => raise bug "non conid"
                            )
                      )
                      varE
              in
                case specTstr of
                  V.TSTR specTfun =>
                  (case strTstr of
                     V.TSTR strTfun => (checkTfun name (specTfun, strTfun) ; specTstr)
                   | V.TSTR_DTY {tfun=strTfun, ...} =>
                     (checkTfun name (specTfun, strTfun); specTstr)
                  )
                | V.TSTR_DTY {tfun=specTfun,formals, conSpec,...} =>
                  (case strTstr of
                     V.TSTR strTfun =>
                     (EU.enqueueError
                        (loc,E.SIGDtyRequired("270",{longid=path@[name]}));
                     specTstr)
                   | V.TSTR_DTY {tfun=strTfun,
                                 varE=strVarE,
                                 formals=strFormals,
                                 conSpec=strConSpec,...} =>
                     (checkTfun name (specTfun, strTfun);
                      let
                        val result = N.checkConSpec 
                                       N.emptyTypIdEquiv
                                       ((formals, conSpec),
                                        (strFormals, strConSpec))
                      in
                        case result of
                          N.SUCCESS => ()
                        | _ =>
                          EU.enqueueError
                            (loc,E.SIGDtyMismatch
                                   ("280",{longid=path@[name ^ "(4)"]}))
                      end;
                      checkVarE strVarE;
                      V.TSTR_DTY{tfun=specTfun, formals=formals, conSpec=conSpec, varE=strVarE}
                     )
                  )
              end
                
          fun checkTyE (specTyE, strTyE) =
               SEnv.foldri
                (fn (name, specTstr, tyE) =>
                     case SEnv.find (strTyE, name) of
                       NONE => 
                       (EU.enqueueError
                          (loc,E.SIGTypUndefined("290",{longid=path@[name]}));
                        tyE)
                     | SOME strTstr => 
                       let
                         val str = checkTstr name (specTstr, strTstr)
                       in
                         SEnv.insert(tyE, name, str)
                       end
                )
                SEnv.empty
                specTyE

          fun isTrans ty = 
              let
                exception OPAQUE 
                fun trace ty =
                    case ty of
                      I.TYWILD => ()
                    | I.TYERROR => ()
                    | I.TYVAR _  => ()
                    | I.TYRECORD tyLabelenvMap =>
                      LabelEnv.app trace tyLabelenvMap
                    | I.TYCONSTRUCT {typ={path, tfun}, args} =>
                      (traceTfun tfun; List.app trace args)
                    | I.TYFUNM (tyList, ty) =>
                      (List.app trace tyList; trace ty)
                    | I.TYPOLY (kindedTvarList, ty) => trace ty
                    | I.INFERREDTY ty => ()
                and traceTfun tfun = 
                    case tfun of
                      I.TFUN_DEF {iseq, formals, realizerTy} => trace realizerTy
                    | I.TFUN_VAR (ref tfunkind) => traceTfunkind tfunkind
                and traceTfunkind tfunkind =
                    case tfunkind of
                      I.TFUN_DTY _ => ()
                    | I.TFV_SPEC _ => ()
                    | I.TFV_DTY _ => ()
                    | I.REALIZED {id, tfun} => traceTfun tfun
                    | I.INSTANTIATED _ => raise OPAQUE
                    | I.FUN_DTY _ => ()
              in
                case mode of 
                  Trans => true
                | Opaque => ((trace ty; true) handle OPAQUE => false)
              end
                
          fun checkVarE (specVarE, strVarE) =
              SEnv.foldri
                (fn (name, specIdStatus, (varE, icdeclList)) =>
                    case specIdStatus of
                      I.IDSPECVAR specTy =>
                      let
                        fun makeDecl icexp =
                            let
                              val icexp = I.ICSIGTYPED
                                            {path=path@[name],
                                             icexp=icexp,
                                             revealKey=revealKey,
                                             ty=specTy,
                                             loc=loc}
                              val newId = VarID.generate()
                              val icpat =
                                  I.ICPATVAR ({path=path@[name],id=newId}, loc)
                            in
                              (SEnv.insert(varE, name, I.IDVAR_TYPED {id=newId, ty=specTy}),
                               I.ICVAL(Ty.emptyScopedTvars,[(icpat,icexp)],loc)
                               :: icdeclList)
                            end
                        fun makeTypdecl (icexp, idstatusActualTyOpt) =
                            case idstatusActualTyOpt of
                              SOME (actualTy, idstatus) =>
                              if isTrans specTy andalso
                                 N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (specTy, actualTy) 
                              then (SEnv.insert(varE, name, idstatus), icdeclList)
                              else makeDecl icexp
                            | NONE => makeDecl icexp
                      in
                        case SEnv.find(strVarE, name) of
                          NONE =>
                          (EU.enqueueError
                             (loc, E.SIGVarUndefined
                                     ("300",{longid = path@[name]}));
                           (varE, icdeclList)
                          )
                        | SOME (I.IDVAR id) => 
                          makeTypdecl (I.ICVAR ({path=path@[name],id=id},loc), NONE)
                        | SOME (idstatus as I.IDVAR_TYPED {id, ty}) => 
                          makeTypdecl (I.ICVAR ({path=path@[name],id=id},loc), SOME (ty, idstatus))
                        | SOME (idstatus as I.IDEXVAR {path, ty, used, loc, version, internalId}) => 
                          let
                            val path = 
                                case version of
                                  NONE => path 
                                | SOME i => path @ [Int.toString i]
                          in
                            (used := true;
                             makeTypdecl (I.ICEXVAR ({path=path,ty=ty},loc), SOME (ty, idstatus))
                            )
                          end
                        | SOME (I.IDEXVAR_TOBETYPED _) =>  raise bug "IDEXVAR_TOBETYPED"
                        | SOME (idstatus as I.IDBUILTINVAR {primitive, ty}) => 
                          makeTypdecl
                            (I.ICBUILTINVAR {primitive=primitive,ty=ty,loc=loc}, 
                             SOME (ty, idstatus))
                        | SOME (I.IDCON {id, ty}) => 
                          makeTypdecl
                            (I.ICCON ({path=path@[name],ty=ty, id=id}, loc), NONE)
                        | SOME (I.IDEXN {id, ty}) => 
                          makeTypdecl
                            (I.ICEXN ({path=path@[name],ty=ty, id=id},loc), NONE)
                        | SOME (I.IDEXNREP {id, ty}) => 
                          makeTypdecl
                            (I.ICEXN ({path=path@[name],ty=ty, id=id},loc), NONE)
                        | SOME (I.IDEXEXN {path, ty, used, loc, version}) => 
                          let
                            val path = 
                                case version of
                                  NONE => path 
                                | SOME i => path @ [Int.toString i]
                          in
                            (used := true;
                             makeTypdecl (I.ICEXEXN ({path=path,ty=ty},loc), NONE)
                            )
                          end
                        | SOME (I.IDEXEXNREP {path, ty, used, loc, version}) => 
                          let
                            val path = 
                                case version of
                                  NONE => path 
                                | SOME i => path @ [Int.toString i]
                          in
                            (used := true;
                             makeTypdecl (I.ICEXEXN ({path=path,ty=ty},loc), NONE)
                            )
                          end
                        | SOME (I.IDOPRIM {id, overloadDef, used, loc}) => 
                          (used := true;
                           makeTypdecl (I.ICOPRIM ({path=path@[name],id=id},loc), NONE)
                          )
                        | SOME (I.IDSPECVAR _) => raise bug "IDSPECVAR"
                        | SOME (I.IDSPECEXN _) => raise bug "IDSPECEXN"
                        | SOME I.IDSPECCON => raise bug "IDSPECCON"
                      end
                    | I.IDSPECEXN ty1 => 
                      (case SEnv.find(strVarE, name) of
                         NONE =>
                         (EU.enqueueError
                            (loc,
                             E.SIGVarUndefined("310",{longid = path@[name]}));
                          (varE, icdeclList)
                         )
                       | SOME (idstatus as I.IDEXN {id, ty=ty2}) => 
                         let
                           val ty1 = N.reduceTy TvarMap.empty ty1
                           val ty2 = N.reduceTy TvarMap.empty ty2
                         in
                           (* we must return ty1 instead of ty2 here,
                              since ty1 may be abstracted *)
                           if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1, ty2) then
                             (SEnv.insert(varE,
                                          name,
                                          I.IDEXN {id=id, ty=ty1}),
                              icdeclList)
                           else 
                             (EU.enqueueError
                                (loc,
                                 E.SIGExnType("320",{longid = path@[name]}));
                              (varE, icdeclList)
                             )
                         end
                       | SOME (idstatus as I.IDEXNREP {id, ty=ty2}) =>
                         let
                           val ty1 = N.reduceTy TvarMap.empty ty1
                           val ty2 = N.reduceTy TvarMap.empty ty2
                         in
                           if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1, ty2) then
                             (SEnv.insert(varE, name, idstatus), icdeclList)
                           else 
                             (EU.enqueueError
                                (loc,
                                 E.SIGExnType("330",{longid = path@[name]}));
                              (varE, icdeclList)
                             )
                         end
                       | SOME (idstatus as I.IDEXEXN {path, ty=ty2, used, loc, version}) => 
                         let
                           val _ = used := true
                           val ty1 = N.reduceTy TvarMap.empty ty1
                           val ty2 = N.reduceTy TvarMap.empty ty2
                         in
                           if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1, ty2) then
                             (SEnv.insert(varE, name, idstatus), icdeclList)
                           else 
                             (EU.enqueueError
                                (loc, E.SIGExnType
                                        ("340",{longid = path@[name]}));
                              (varE, icdeclList)
                             )
                         end
                       | SOME (idstatus as I.IDEXEXNREP {path, ty=ty2, used, loc, version}) => 
                         let
                           val _ = used := true
                           val ty1 = N.reduceTy TvarMap.empty ty1
                           val ty2 = N.reduceTy TvarMap.empty ty2
                         in
                           if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1, ty2) then
                             (SEnv.insert(varE, name, idstatus), icdeclList)
                           else 
                             (EU.enqueueError
                                (loc, E.SIGExnType
                                        ("340",{longid = path@[name]}));
                              (varE, icdeclList)
                             )
                         end
                       | _ =>
                         (EU.enqueueError
                            (loc, E.SIGExnExpected
                                    ("350",{longid = path@[name]}));
                          (varE, icdeclList)
                         )
                      )
                    | I.IDSPECCON =>
                      (case SEnv.find(strVarE, name) of
                         NONE =>
                         (EU.enqueueError
                            (loc,
                             E.SIGVarUndefined("360",{longid = path@[name]}));
                          (varE, icdeclList)
                         )
                       | SOME (idstatus as I.IDCON {id,ty}) => 
                         (SEnv.insert(varE, name, idstatus), icdeclList)
                       | SOME _ => 
                         (EU.enqueueError
                            (loc, E.SIGConNotFound
                                    ("370",{longid = path@[name ^ ":(4)"]}));
                          (varE, icdeclList)
                         )
                      )
                    | I.IDCON {id, ty} =>
                      (case SEnv.find(strVarE, name) of
                         NONE =>
                         (EU.enqueueError
                            (loc, E.SIGVarUndefined
                                    ("380",{longid = path@[name]}));
                          (varE, icdeclList)
                         )
                       | SOME (idstatus as I.IDCON {id=id2, ty=ty2}) => 
                         if ConID.eq(id, id2) then 
                           (SEnv.insert(varE, name, idstatus), icdeclList)
                         else 
                           (EU.enqueueError
                              (loc, E.SIGConNotFound
                                      ("390",{longid = path@[name ^ ":(5)"]}));
                            (varE, icdeclList)
                           )
                       | SOME _ => 
                         (EU.enqueueError
                            (loc, E.SIGConNotFound
                                    ("400",{longid = path@[name ^ ":(6)"]}));
                          (varE, icdeclList)
                         )
                      )
                    | _ =>
                      (U.print "\ncheckVarE\n";
                       U.printIdstatus specIdStatus;
                       U.print "\n";
                       raise bug "illeagal idstatus"
                      )
                )
                (SEnv.empty, nil)
                specVarE

          fun checkStrE (V.STR specEnvMap, V.STR strEnvMap) =
              SEnv.foldri
                (fn (name, {env=specEnv, strKind=specStrKind}, (strE, icdeclList)) =>
                    case SEnv.find(strEnvMap, name) of
                      NONE => 
                      (EU.enqueueError
                         (loc, E.SIGStrUndefined("410",{longid=path@[name]}));
                       (strE, icdeclList))
                    | SOME {env=strEnv, strKind=strStrKind} =>
                      let
                        val (env, icdeclList1) = checkEnv (path@[name]) (specEnv, strEnv)
                      in
                        (SEnv.insert(strE, name, {env=env, strKind=strStrKind}), icdeclList@icdeclList1)
                      end
                )
                (SEnv.empty, nil)
                specEnvMap

          val tyE = checkTyE (specTyE, strTyE)
          val (varE, icdeclList1) = checkVarE(specVarE, strVarE)
          val (strE, icdeclList2) = checkStrE (specStrE, strStrE)
          val env = V.ENV{varE=varE, tyE=tyE, strE=V.STR strE}
        in
          if EU.isAnyError () then raise SIGCHECK
          else (env, icdeclList1@icdeclList2)
        end
      fun makeOpaqueInstanceEnv path env =
        let
          fun makeOpaqueInstanceTstr name (tstr, env) =
              case tstr of 
                V.TSTR tfun =>
                (case I.derefTfun tfun of
                   I.TFUN_VAR(tfv as ref (I.INSTANTIATED {tfunkind,tfun})) =>
                   (case tfunkind of (* creating a return env *)
                      I.TFV_SPEC {id, iseq, ...} => 
                      let
                        val formals = I.tfunFormals tfun
                        val liftedTys = I.tfunLiftedTys tfun
                        val runtimeTy = 
                            case I.tfunRuntimeTy tfun of
                              SOME ty => ty
                            | NONE => raise bug "runtimeTy"
                        val newTfunkind =
                            I.TFUN_DTY {id=id,
                                        iseq=iseq,
                                        formals=formals,
                                        runtimeTy=runtimeTy,
                                        conSpec=SEnv.empty,
                                        originalPath=path,
                                        liftedTys=liftedTys,
                                        dtyKind=I.OPAQUE
                                                  {tfun=tfun,
                                                   revealKey=revealKey}
                                       }
                        val _ = tfv := newTfunkind
                        val env = V.rebindTstr(env,name,V.TSTR (I.TFUN_VAR tfv))
                      in
                        env
                      end
                    | I.TFV_DTY {id, iseq, ...} => 
                      let
                        val formals = I.tfunFormals tfun
                        val liftedTys = I.tfunLiftedTys tfun
                        val runtimeTy = 
                            case I.tfunRuntimeTy tfun of
                              SOME ty => ty
                            | NONE => raise bug "runtimeTy"
                        val newTfunkind =
                            I.TFUN_DTY {id=id,
                                        iseq=iseq,
                                        formals=formals,
                                        runtimeTy=runtimeTy,
                                        conSpec=SEnv.empty,
                                        originalPath=path,
                                        liftedTys=liftedTys,
                                        dtyKind=
                                        I.OPAQUE
                                          {tfun=tfun, revealKey=revealKey}
                                       }
                        val _ = tfv := newTfunkind
                        val newTfun = I.TFUN_VAR tfv
                        val env = V.rebindTstr(env, name,V.TSTR newTfun)
                      in
                        env
                      end
                    | _ => raise bug "non tfv (5)"
                   )
                 | I.TFUN_VAR _ => V.rebindTstr(env, name, tstr)
                 | I.TFUN_DEF _ => V.rebindTstr(env, name, tstr)
                )
              | V.TSTR_DTY {tfun, varE, ...} =>
                (case I.derefTfun tfun of
                   I.TFUN_VAR
                     (tfv as ref (I.INSTANTIATED{tfunkind,tfun=strTfun})) =>
                      (case tfunkind of
                         I.TFV_DTY {id, iseq, formals, conSpec, liftedTys} =>
                         let
                           val runtimeTy = 
                               case I.tfunRuntimeTy strTfun of
                                 SOME ty => ty
                               | NONE => raise bug "runtimeTy"
                           val newTfunkind =
                               I.TFUN_DTY {id=id,
                                           iseq=iseq,
                                           formals=formals,
                                           runtimeTy=runtimeTy,
                                           conSpec=conSpec,
                                           originalPath=path,
                                           liftedTys=liftedTys,
                                           dtyKind=
                                           I.OPAQUE
                                             {tfun=strTfun,revealKey=revealKey}
                                          }
                           val _ = tfv := newTfunkind
                           val returnTy =
                               I.TYCONSTRUCT
                                 {typ={path=path@[name],tfun=tfun},
                                  args= map (fn tv=>I.TYVAR tv) formals}
                           val (varE, conbind) =
                               SEnv.foldri
                                 (fn (name, tyOpt, (varE, conbind)) =>
                                     let
                                       val conId = ConID.generate()
                                       val conTy =
                                           case tyOpt of
                                             NONE => 
                                             (case formals of 
                                                nil => returnTy
                                              | _ => 
                                                I.TYPOLY
                                                  (
                                                   map 
                                                     (fn tv=>(tv,I.UNIV))
                                                     formals,
                                                   returnTy
                                                  )
                                             )
                                           | SOME ty => 
                                             case formals of 
                                               nil =>
                                               I.TYFUNM([ty], returnTy)
                                             | _ => 
                                               I.TYPOLY
                                                 (
                                                  map
                                                    (fn tv =>(tv,I.UNIV))
                                                    formals,
                                                  I.TYFUNM([ty], returnTy)
                                                 )
                                       val conInfo =
                                           {path=path@[name],ty=conTy,id=conId}
                                       val idstatus =
                                           I.IDCON{id=conId,ty=conTy}
                                     in
                                       (SEnv.insert(varE, name, idstatus),
                                        {datacon=conInfo,tyOpt=tyOpt}
                                        :: conbind)
                                     end
                                 )
                                 (SEnv.empty, nil)
                                 conSpec
                           val newTstr = V.TSTR_DTY
                                           {tfun=I.TFUN_VAR tfv,
                                            varE=varE,
                                            formals=formals,
                                            conSpec=conSpec}
                           val env = V.rebindTstr(env, name, newTstr)
                           val env = V.envWithVarE(env, varE)
                         in
                           env
                         end
                       | _ => raise bug "non dty tfv (1)"
                      )
                 | _ => V.rebindTstr(env, name, tstr)
                )

          fun makeOpaqueInstanceTyE tyE env =
              SEnv.foldri
                (fn (name, tstr, env) => makeOpaqueInstanceTstr name (tstr, env)
                )
                env
                tyE
          fun makeOpaqueInstanceStrE (V.STR strEnvMap) env =
              let
                val env =
                    SEnv.foldri
                      (fn (name, {env=strEnv, strKind}, env) =>
                          let
                            val strEnv = makeOpaqueInstanceEnv (path@[name]) strEnv
                            val strKind = V.STRENV (StructureID.generate())
                          in
                            V.rebindStr(env, name, {env=strEnv, strKind=strKind}) 
                          end
                      )
                      env
                      strEnvMap
              in
                env
              end

          val V.ENV {varE, tyE, strE} = env
          val env = makeOpaqueInstanceTyE tyE env
          val env = makeOpaqueInstanceStrE strE env
        in
          env
        end

      fun makeTransInstanceEnv path env =
        let
          val V.ENV {varE, tyE, strE} = env
          fun makeTransInstanceTstr name (tstr, tyE) =
              case tstr of 
                V.TSTR tfun =>
                (case I.derefTfun tfun of
                   I.TFUN_VAR (tfv as ref tfunkind) =>
                   (case tfunkind of
                      I.INSTANTIATED {tfunkind, tfun} =>
                      (tfv := I.REALIZED{tfun=tfun,id=I.tfunkindId tfunkind};
                       SEnv.insert(tyE, name, V.TSTR tfun)
                      )
                    | I.TFV_SPEC _ => raise bug "non instantiated tfv (3)"
                    | I.TFV_DTY _ => raise bug "non instantiated tfv (3)"
                    | I.TFUN_DTY _ => SEnv.insert(tyE, name, tstr)
                    | _ => raise bug "non instantiated tfv (3)"
                   )
                 | _ => SEnv.insert(tyE, name, tstr)
                )
              | V.TSTR_DTY {tfun=specTfun, varE=tstrVarE, ...} =>
                (case I.derefTfun specTfun of
                   I.TFUN_VAR (tfv as ref tfunkind) =>
                   (case tfunkind of
                      I.INSTANTIATED {tfunkind, tfun} =>
                      (tfv := I.REALIZED{tfun=tfun,id=I.tfunkindId tfunkind};
                       case I.derefTfun tfun of 
                        I.TFUN_VAR
                          (ref (I.TFUN_DTY{id,iseq,formals,runtimeTy,conSpec,originalPath,liftedTys,dtyKind})) =>
                        let
                          val varE =
                              SEnv.mapi
                                (fn (name, _) =>
                                    case SEnv.find(varE, name) of
                                      SOME idstatus => idstatus
                                    | NONE => raise bug "id not found"
                                )
                                tstrVarE
                        in
                          SEnv.insert
                            (tyE,
                             name,
                             V.TSTR_DTY {tfun=tfun,
                                         varE=varE,
                                         formals=formals,
                                         conSpec=conSpec}
                            )
                        end
                      | _ => raise bug "non dty instance"
                      )
                    | I.TFV_SPEC _ => raise bug "non instantiated tfv (3)"
                    | I.TFV_DTY _ => raise bug "non instantiated tfv (3)"
                    | I.TFUN_DTY _ => SEnv.insert(tyE, name, tstr)
                    | _ => raise bug "non instantiated tfv (4)"
                   )
                 | _ => SEnv.insert(tyE, name, tstr)
                )

          fun makeTransInstanceTyE tyE =
              SEnv.foldri
                (fn (name, tstr, tyE) =>
                    makeTransInstanceTstr name (tstr, tyE)
                )
                SEnv.empty
                tyE
          fun makeTransInstanceStrE (V.STR strEnvMap) =
              let
                val strEnvMap =
                    SEnv.foldri
                      (fn (name, {env,strKind}, strEnvMap) =>
                          let
                            val env = makeTransInstanceEnv (path@[name]) env
                            val strKind = V.STRENV (StructureID.generate())
                          in
                            SEnv.insert(strEnvMap, name, {env=env,strKind=strKind})
                          end
                      )
                      SEnv.empty
                      strEnvMap
              in
                V.STR strEnvMap
              end
          val tyE = makeTransInstanceTyE tyE
          val strE = makeTransInstanceStrE strE
        in
          V.ENV {varE=varE, tyE=tyE, strE=strE}
        end

      fun makeInstanceEnv path env =
          case mode of 
            Opaque => makeOpaqueInstanceEnv path env
          | Trans => makeTransInstanceEnv path env

      (* sigCheck body *)
      val path = #strPath param
      val specEnv = #specEnv param
      val strEnv = #strEnv param
      val _ = instantiateEnv path (specEnv, strEnv)
      val (env, icdeclList1) = checkEnv path (specEnv, strEnv)
      val env = makeInstanceEnv path env
      val env = N.reduceEnv env
    in
      (env, icdeclList1)
    end

  fun refreshEnv (typidSet, exnIdSubst) specEnv
      : (S.tfvSubst * S.conIdSubst) * V.env =
    let
      val tfvMap = TF.tfvsEnv TF.allTfvKind nil (specEnv, TfvMap.empty)
      val (tfvSubst, conIdSubst) = 
          TfvMap.foldri
          (fn (tfv as ref (I.TFV_SPEC {iseq, formals,...}),path,
               (tfvSubst, conIdSubst)) =>
              let
                val id = TypID.generate()
                val newTfv =
                    I.mkTfv (I.TFV_SPEC{id=id,iseq=iseq,formals=formals})
              in 
                (TfvMap.insert(tfvSubst, tfv, newTfv), conIdSubst)
              end
            | (tfv as ref (I.INSTANTIATED {tfunkind, tfun}),
               path, (tfvSubst, conIdSubst)) =>
              let
                val newTfv = I.mkTfv (I.INSTANTIATED {tfunkind=tfunkind, tfun=tfun})
              in 
                (TfvMap.insert(tfvSubst, tfv, newTfv), conIdSubst)
              end
            | (tfv as ref (I.TFV_DTY {iseq,formals,conSpec,liftedTys,...}),
               path, (tfvSubst, conIdSubst)) =>
              let
                val id = TypID.generate()
                val newTfv =
                    I.mkTfv (I.TFV_DTY{id=id,
                                         iseq=iseq,
                                         conSpec=conSpec,
                                         liftedTys=liftedTys,
                                         formals=formals}
                          )
              in 
                (TfvMap.insert(tfvSubst, tfv, newTfv), conIdSubst)
              end
            | (tfv as
                   ref(I.TFUN_DTY
                         {id,iseq,formals,runtimeTy,originalPath,
                          conSpec,liftedTys,dtyKind}),
               path, (tfvSubst, conIdSubst)) =>
              if TypID.Set.member(typidSet, id) then
                let
                  val (name, path) = case List.rev path of
                                       h::tl => (h, List.rev tl)
                                     | _ => raise bug "nil path"
                  val id = TypID.generate()
                  val newTfv =
                      I.mkTfv (I.TFUN_DTY {id=id,
                                           iseq=iseq,
                                           formals=formals,
                                           runtimeTy=runtimeTy,
                                           conSpec=conSpec,
                                           originalPath=originalPath,
                                           liftedTys=liftedTys,
                                           dtyKind=dtyKind
                                          }
                            )
                  val conIdSubst =
                      SEnv.foldri
                      (fn (name, _, conIdSubst) =>
                          case V.findId(specEnv, path@[name]) of
                            SOME (I.IDCON {id, ty}) =>
                            let
                              val newId = ConID.generate()
                            in
                              ConID.Map.insert(conIdSubst, id, 
                                               I.IDCON{id=newId, ty=ty}
                                              )
                            end
                          | _ => conIdSubst
                      )
                      conIdSubst
                      conSpec
                in 
                  (TfvMap.insert(tfvSubst, tfv, newTfv), conIdSubst)
                end
              else (tfvSubst, conIdSubst)
            | _ => raise bug "non tfv (11)"
          )
          (TfvMap.empty, ConID.Map.empty)
          tfvMap
          handle exn => raise exn
      val _ =
          TfvMap.app
          (fn (tfv as 
                   ref (I.TFV_DTY{iseq,formals,conSpec,liftedTys,id})) =>
              let
                val conSpec =
                    SEnv.map
                    (fn tyOpt =>
                        Option.map (Subst.substTfvTy tfvSubst) tyOpt)
                    conSpec
              in
                tfv:=
                    I.TFV_DTY
                      {iseq=iseq,
                       formals=formals,
                       conSpec=conSpec,
                       liftedTys=liftedTys,
                       id=id}
              end
            | (tfv as ref (I.TFUN_DTY {iseq,
                                       formals,
                                       conSpec,
                                       originalPath,
                                       runtimeTy,
                                       liftedTys,
                                       id,
                                       dtyKind
                                      })) =>
              let
                val dtyKind =
                    case dtyKind of
                      I.OPAQUE{tfun, revealKey} => 
                      I.OPAQUE{tfun=Subst.substTfvTfun tfvSubst tfun,
                                revealKey=revealKey}
                    | _ => dtyKind
                val conSpec =
                    SEnv.map
                    (fn tyOpt =>
                        Option.map (Subst.substTfvTy tfvSubst) tyOpt)
                    conSpec
              in
                tfv:=
                    I.TFUN_DTY
                      {iseq=iseq,
                       formals=formals,
                       runtimeTy=runtimeTy,
                       conSpec=conSpec,
                       originalPath=originalPath,
                       liftedTys=liftedTys,
                       dtyKind=dtyKind,
                       id=id}
              end
            | _ => ())
          tfvSubst
          handle exn => raise exn
      val subst = {tvarS=S.emptyTvarSubst,
                   tfvS=S.emptyTfvSubst,
                   exnIdS=exnIdSubst,
                   conIdS=conIdSubst} 
      val env =Subst.substTfvEnv tfvSubst specEnv
      val env =Subst.substEnv subst env
    in
      ((tfvSubst, conIdSubst), env)
    end

end
end
