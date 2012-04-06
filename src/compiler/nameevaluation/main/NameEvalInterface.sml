(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
(* the initial error code of this file : EI-001 *)
structure NameEvalInterface :
sig
  type interfaceEnv
  val evalPitopdecList : NameEvalEnv.topEnv
                         -> PathSet.set * PatternCalcInterface.pitopdec list
                         -> PathSet.set * NameEvalEnv.topEnv * IDCalc.icdecl list
  val evalPistr : string list
                  -> NameEvalEnv.topEnv
                     -> PathSet.set * PatternCalcInterface.pistrexp
                        -> PathSet.set * NameEvalEnv.env * IDCalc.icdecl list
  val internalizeEnv : NameEvalEnv.env -> NameEvalEnv.env
  val evalInterfaces : NameEvalEnv.topEnv
                       -> PatternCalcInterface.interfaceDec list
                          -> interfaceEnv
end
=
struct
local
  structure I = IDCalc
  structure T = Types
  structure V = NameEvalEnv
  structure BV = BuiltinEnv
  structure PI = PatternCalcInterface
  structure PC = PatternCalc
  structure U = NameEvalUtils
  structure EU = UserErrorUtils
  structure E = NameEvalError
  structure AI = AbsynInterface
  structure A = Absyn
  structure N = NormalizeTy
  structure Ty = EvalTy
  structure ITy = EvalIty
  structure Sig = EvalSig
  structure SC = SigCheck
  structure L = SetLiftedTys
  structure S = Subst
  structure FU = FunctorUtils

  fun bug s = Control.Bug ("NameEvalInterface: " ^ s)
  val nilPath = nil

  (* FIXME factor out this def into some unique plcae *)
  val FUNCORPREFIX = "_"


in
  val revealKey = RevealID.generate() (* global reveal key *)

  type interfaceEnv = {decls: IDCalc.icdecl list,
                       source: PatternCalcInterface.pitopdec list,
                       topEnv: NameEvalEnv.topEnv} InterfaceID.Map.map

  fun genTypedExternVarsIdstatus loc path idstatus (externSet, icdecls) =
      case idstatus of
        I.IDVAR varId => (externSet, idstatus, icdecls)
      | I.IDVAR_TYPED {id, ty} => (externSet, idstatus, icdecls)
      | I.IDEXVAR {path, ty, used, loc, version, internalId} =>
        let
          val path = case version of
                       NONE => path
                     | SOME i => path @ [Int.toString i]
        in
          if PathSet.member(externSet, path) 
          then (externSet, 
                I.IDEXVAR {path=path, ty=ty, used=used, loc=loc, 
                           version=version, internalId=internalId}, 
                icdecls)
          else
            (PathSet.add(externSet, path),
             I.IDEXVAR {path=path, ty=ty, used=used, loc=loc, 
                        version=version, internalId=internalId},
             I.ICEXTERNVAR ({path=path, ty=ty}, loc)::icdecls)
        end
      | I.IDEXVAR_TOBETYPED _ => raise bug "IDEXVAR_TOBETYPED"
      | I.IDBUILTINVAR {primitive, ty} => (externSet, idstatus, icdecls)
      | I.IDCON {id, ty} => (externSet, idstatus, icdecls)
      | I.IDEXN {id, ty} => (externSet, idstatus, icdecls)
      | I.IDEXNREP {id, ty} => (externSet, idstatus, icdecls)
      | I.IDEXEXN {path, ty, used, loc, version} => 
        let
          val path = case version of
                       NONE => path
                     | SOME i => path @ [Int.toString i]
        in
          if PathSet.member(externSet, path) 
          then (externSet, 
                I.IDEXEXN {path=path, ty=ty, used=used, loc=loc, version=version}, 
                icdecls)
          else
            (PathSet.add(externSet, path),
             I.IDEXEXN {path=path, ty=ty, used=used, loc=loc, version=version},
             I.ICEXTERNEXN ({path=path, ty=ty}, loc)::icdecls)
        end
      | I.IDEXEXNREP {path, ty, used, loc, version} => (externSet, idstatus, icdecls)
      | I.IDOPRIM _ => (externSet, idstatus, icdecls)
      | I.IDSPECVAR ty => raise bug "IDSPECVAR in genTypedExternVars"
      | I.IDSPECEXN ty => raise bug "IDSPECEXN in genTypedExternVars"
      | I.IDSPECCON  => raise bug "IDSPECCON in genTypedExternVars"
  fun genTypedExternVarsVarE loc path varE (externSet, icdecls) =
      SEnv.foldli
      (fn (name, idstatus, (externSet, varE, icdecls)) =>
          let
            val (externSet, idstatus, icdecls) = 
                genTypedExternVarsIdstatus loc (path@[name]) idstatus (externSet, icdecls)
            val varE = SEnv.insert(varE, name, idstatus)
          in
            (externSet, varE, icdecls)
          end
      )
      (externSet, SEnv.empty, icdecls)
      varE
  fun genTypedExternVarsEnv loc path (V.ENV{varE, tyE, strE}) (externSet, icdecls) =
      let
        val (externSet, varE, icdecls) = genTypedExternVarsVarE loc path varE (externSet, icdecls)
        val (extdenSet, strE, icdecls) = genTypedExternVarsStrE loc path strE (externSet, icdecls)
        val env = V.ENV{varE=varE, tyE=tyE, strE=strE}
      in
        (externSet, env, icdecls)
      end
  and genTypedExternVarsStrE loc path (V.STR strEntryMap) (externSet, icdecls) =
      let
        val (externSet, strEntryMap, icdecls) =
            SEnv.foldli
              (fn (name, {env, strKind}, (externSet, strEntryMap, icdecls)) =>
                  let
                    val (externSet, env, icdecls) =
                        genTypedExternVarsEnv loc (path@[name]) env (externSet, icdecls)
                    val strEntryMap = SEnv.insert(strEntryMap, name, {env=env, strKind=strKind})
                  in
                    (externSet, strEntryMap, icdecls)
                  end
              )
              (externSet, SEnv.empty, icdecls)
              strEntryMap
      in
        (externSet, V.STR strEntryMap, icdecls)
      end

  fun evalPidec path (topEnv as {Env=env, FunE, SigE}) (externSet, pidec) =
      case pidec of
        PI.PIVAL {scopedTvars, vid=name, body, loc} =>
        let
          val (tvarEnv, kindedTvars) =
              Ty.evalScopedTvars loc Ty.emptyTvarEnv env scopedTvars
          fun evalOverloadCase {tyvar, expTy, matches, loc} =
              let
                val tvar = Ty.evalTvar loc tvarEnv tyvar
                val expTy = Ty.evalTy tvarEnv env expTy
                val matches = map evalMatch matches
              in
                {tvar=tvar, expTy=expTy, matches=matches, loc=loc}
              end
          and evalMatch {instTy, instance} =
              let
                val instTy = Ty.evalTy tvarEnv env instTy
                val instance = evalInstance instance
              in
                {instTy=instTy, instance=instance}
              end
          and evalInstance instance =
              case instance of
                AI.INST_OVERLOAD overloadCase =>
                I.INST_OVERLOAD (evalOverloadCase overloadCase)
              | AI.INST_LONGVID {vid} =>
                let
                  fun error e =
                      (EU.enqueueError (loc, e);
                       I.INST_EXVAR ({path=path, used=ref false, ty=I.TYERROR}, loc))
                in
                  (case V.lookupId env vid of
                     I.IDEXVAR {path, ty, used, loc, version, internalId} =>
                     let
                       val path = case version of
                                    NONE => path
                                  | SOME i => path @ [Int.toString i]
                     in
                       I.INST_EXVAR ({path=path, used = used, ty=ty}, loc)
                     end
                   | I.IDEXVAR_TOBETYPED _ => raise bug "IDEXVAR_TOBETYPED"
                   | I.IDBUILTINVAR {primitive, ty} =>
                     I.INST_PRIM ({primitive=primitive, ty=ty}, loc)
                   | I.IDVAR id =>
                     error (E.InvalidOverloadInst("EI-010", {longid=vid}))
                   | I.IDVAR_TYPED {id, ty} =>
                     error (E.InvalidOverloadInst("EI-010", {longid=vid}))
                   | I.IDOPRIM _ =>
                     error (E.InvalidOverloadInst("EI-020", {longid=vid}))
                   | I.IDCON _ =>
                     error (E.InvalidOverloadInst("EI-030", {longid=vid}))
                   | I.IDEXN _ =>
                     error (E.InvalidOverloadInst("EI-040", {longid=vid}))
                   | I.IDEXNREP _ =>
                     error (E.InvalidOverloadInst("EI-050", {longid=vid}))
                   | I.IDEXEXN {path,ty, used,loc, version} =>
                     error (E.InvalidOverloadInst("EI-060", {longid=vid}))
                   | I.IDEXEXNREP {path,ty, used, loc, version} =>
                     error (E.InvalidOverloadInst("EI-060", {longid=vid}))
                   | I.IDSPECVAR _ => raise bug "SPEC id status"
                   | I.IDSPECEXN _ => raise bug "SPEC id status"
                   | I.IDSPECCON => raise bug "SPEC id status")
                  handle V.LookupId =>
                         error (E.VarNotFound("EI-070",{longid=vid}))
                end
          val path = path@[name]
        in
          case body of
            AI.VAL_EXTERN {ty} =>
            let
              val ty = Ty.evalTy tvarEnv env ty
              val ty = 
                  case kindedTvars of
                    nil => ty
                  | _ => I.TYPOLY(kindedTvars,ty)
              val idstatus = I.IDEXVAR {path=path, 
                                        ty=ty,
                                        used=ref false, 
                                        loc=loc,
                                        internalId=NONE,
                                        version=NONE}
              val icdecl = I.ICEXTERNVAR ({path=path, ty=ty}, loc)
              val externSet = PathSet.add(externSet, path)
            in
              (externSet, V.rebindId (V.emptyEnv, name, idstatus), [icdecl])
            end
          | AI.VAL_EXTERN_WITHNAME {ty, externPath} =>
            let
              val ty = Ty.evalTy tvarEnv env ty
              val ty = 
                  case kindedTvars of
                    nil => ty
                  | _ => I.TYPOLY(kindedTvars,ty)
              val idstatus = I.IDEXVAR {path=externPath, ty=ty, used=ref false, loc=loc, 
                                        version=NONE, internalId=NONE}
              val icdecl = I.ICEXTERNVAR ({path=externPath, ty=ty}, loc)
              val externSet = PathSet.add(externSet, externPath)
            in
              (externSet, V.rebindId (V.emptyEnv, name, idstatus), [icdecl])
            end
          | AI.VALALIAS_EXTERN {path} =>
            (case V.findId(env, path) of
               SOME (idstatus as I.IDEXVAR {path, ty, used, loc, version, internalId}) => 
               let
                 val exPath = case version of 
                              NONE => path 
                            | SOME i => path @ [Int.toString i]
               in
                 if PathSet.member(externSet, exPath) then
                   (externSet, V.rebindId  (V.emptyEnv, name, idstatus), nil)
                 else 
                   let
                     val icdecl = I.ICEXTERNVAR ({path=exPath, ty=ty}, loc)
                     val externSet = PathSet.add(externSet, exPath)
                   in
                     (externSet, V.rebindId  (V.emptyEnv, name, idstatus), [icdecl])
                   end
               end
             | SOME (idstatus as I.IDBUILTINVAR _) => 
               (externSet, V.rebindId (V.emptyEnv, name, idstatus), nil)
             | SOME _ => 
               (EU.enqueueError
                  (loc, E.ProvideVarIDExpected("EI-080", {longid = path}));
                (externSet, V.emptyEnv, nil))
             | NONE => 
               (EU.enqueueError
                  (loc, E.ProvideUndefinedID("EI-080", {longid = path}));
                (externSet, V.emptyEnv, nil))
            )
          | AI.VAL_BUILTIN {builtinName, ty} =>
            let
              val ty = Ty.evalTy tvarEnv env ty
              val ty = 
                  case kindedTvars of
                    nil => ty
                  | _ => I.TYPOLY(kindedTvars,ty)
            in
              case BuiltinPrimitive.findPrimitive builtinName of
                SOME primitive => 
                let
                  val idstatus = I.IDBUILTINVAR {primitive=primitive, ty=ty}
                in
                  (externSet, V.rebindId (V.emptyEnv, name, idstatus), nil)
                end
              | NONE => 
                (EU.enqueueError
                   (loc, E.PrimitiveNotFound("EI-080", {name = builtinName}));
                 (externSet, V.emptyEnv, nil))
            end
          | AI.VAL_OVERLOAD overloadCase =>
            let
              val id = OPrimID.generate()
              val overloadCase = evalOverloadCase overloadCase
              val decl = I.ICOVERLOADDEF {boundtvars=kindedTvars,
                                          id=id,
                                          path=path,
                                          overloadCase=overloadCase,
                                          loc = loc}
              val idstatus = I.IDOPRIM {id=id, overloadDef=decl, used=ref false, loc=loc}
              in
              (externSet, V.rebindId (V.emptyEnv, name, idstatus), [decl])
            end
        end
      | PI.PITYPE {tyvars, tycon, ty, loc} =>
        let
          val _ = EU.checkNameDuplication
                    (fn {name, eq} => name)
                    tyvars
                    loc
                    (fn s => E.DuplicateTypParms("EI-090",s))
          val (tvarEnv, tvarList) = Ty.genTvarList Ty.emptyTvarEnv tyvars
          val ty = Ty.evalTy tvarEnv env ty
          val tfun =
              case N.tyForm tvarList ty of
                N.TYNAME {tfun,...} => tfun
              | N.TYTERM ty =>
                let
                  val iseq = N.admitEq tvarList ty
                  val tfun =
                      I.TFUN_DEF {iseq=iseq,
                                  formals=tvarList,
                                  realizerTy=ty
                                 }
                in
                  tfun
                end
        in
          (externSet, V.rebindTstr (V.emptyEnv, tycon, V.TSTR tfun), nil)
        end               

      | PI.PIOPAQUE_TYPE {tyvars, tycon, runtimeTy, loc} =>
        let
          val _ = EU.checkNameDuplication
                    (fn {name, eq} => name)
                    tyvars
                    loc
                    (fn s => E.DuplicateTypParms("EI-090",s))
          val (tvarEnv, tvarList) = Ty.genTvarList Ty.emptyTvarEnv tyvars
          val id = TypID.generate()
          val absTfun =
              I.TFUN_VAR
                (I.mkTfv
                   (I.TFUN_DTY {id=id,
                                iseq=false,
                                formals=tvarList,
                                runtimeTy=runtimeTy,
                                conSpec=SEnv.empty,
                                originalPath=[tycon],
                                liftedTys=I.emptyLiftedTys,
                                dtyKind= I.DTY_INTERFACE
                                }
                   )
                )
        in
          (externSet, V.rebindTstr (V.emptyEnv, tycon, V.TSTR absTfun), nil)
        end

      | PI.PIOPAQUE_EQTYPE {tyvars, tycon, runtimeTy, loc} =>
        let
          val _ = EU.checkNameDuplication
                    (fn {name, eq} => name)
                    tyvars
                    loc
                    (fn s => E.DuplicateTypParms("EI-090",s))
          val (tvarEnv, tvarList) = Ty.genTvarList Ty.emptyTvarEnv tyvars
          val id = TypID.generate()
          val absTfun =
              I.TFUN_VAR
                (I.mkTfv(
                 I.TFUN_DTY {id=id,
                             iseq=true,
                             formals=tvarList,
                             runtimeTy=runtimeTy,
                             conSpec=SEnv.empty,
                             originalPath=[tycon],
                             liftedTys=I.emptyLiftedTys,
                             dtyKind= I.DTY_INTERFACE
                             }
                 )
                )
        in
          (externSet, V.rebindTstr (V.emptyEnv, tycon, V.TSTR absTfun), nil)
        end

      | PI.PITYPEBUILTIN {tycon, builtinName, loc} =>
        (case BV.findTfun builtinName of
           SOME tfun =>
             (externSet, V.rebindTstr (V.emptyEnv, tycon, V.TSTR tfun), nil)
         | NONE =>
           (EU.enqueueError
              (loc, E.BuiltinTyNotFound("EI-100", {name = builtinName}));
            (externSet, V.emptyEnv, nil))
        )

      | PI.PIDATATYPE {datbind, loc} => 
        let
          val (env, icdecls) = Ty.evalDatatype path env (datbind, loc)
        in
          (externSet, env, icdecls)
        end

      | PI.PITYPEREP {tycon, origTycon=path, loc} =>
        (* datatype foo = datatype bar *)
        (
         case V.findTstr(env, path) of
           NONE => (EU.enqueueError
                      (loc, E.DataTypeNameUndefined("EI-110", {longid = path}));
                    (externSet, V.emptyEnv, nil))
         | SOME tstr =>
           let
             val (tstr, varE) =
                 case tstr of
                   V.TSTR_DTY {tfun, varE, formals, conSpec} => (tstr, varE)
                 | _ => 
                   (EU.enqueueError
                      (loc, E.DataTypeNameExpected("EI-130", {longid = path}));
                    (tstr, SEnv.empty))
             val env = V.rebindTstr (V.emptyEnv, tycon, tstr)
             val env = SEnv.foldri
                       (fn (name, idstatus, env) =>
                           V.rebindId(env, name, idstatus))
                       env
                       varE
           in
             (externSet, env, nil)
           end
        )
      | PI.PIEXCEPTION {vid=name, ty=tyOpt, externPath, loc} =>
        let
          val ty =
              case tyOpt of
                NONE => BV.exnTy
              | SOME ty => 
                I.TYFUNM([Ty.evalTy Ty.emptyTvarEnv env ty],
                          BV.exnTy)
          val externPath = case externPath of NONE => path@[name]
                                            | SOME path => path
          val idstatus = I.IDEXEXN {path=externPath, 
                                    ty=ty, 
                                    used=ref false, 
                                    loc=loc,
                                    version=NONE
                                   }
          val icdecl = I.ICEXTERNEXN ({path=externPath, ty=ty}, loc)
          val externSet = PathSet.add(externSet, externPath)
        in
          (externSet, V.rebindId  (V.emptyEnv, name, idstatus), [icdecl])
        end

      | PI.PIEXCEPTIONREP {vid=name, origId=path, loc} =>
        (
         case V.findId(env, path) of
           NONE =>
           (
            EU.enqueueError
              (loc, E.ExceptionNameUndefined("EI-140", {longid = path}));
            (externSet, V.emptyEnv, nil))
         | SOME (idstatus as I.IDEXN exnInfo) => 
           (externSet, V.rebindId  (V.emptyEnv, name, I.IDEXNREP exnInfo), nil)
         | SOME (idstatus as I.IDEXNREP exnInfo) =>
           (externSet, V.rebindId  (V.emptyEnv, name, I.IDEXNREP exnInfo), nil)
         | SOME (idstatus as I.IDEXEXN (exExnInfo as {path, ty, used, loc, version})) => 
           let
             val exPath = case version of 
                            NONE => path
                          | SOME i => path @ [Int.toString i]
           in
             if PathSet.member(externSet, exPath) then
               (externSet, V.rebindId  (V.emptyEnv, name, I.IDEXEXNREP exExnInfo), nil)
             else 
               let
                 val icdecl = I.ICEXTERNEXN ({path=exPath, ty=ty}, loc)
                 val externSet = PathSet.add(externSet, exPath)
               in
                 (externSet, V.rebindId  (V.emptyEnv, name, I.IDEXEXNREP exExnInfo), [icdecl])
               end
           end
         | SOME (idstatus as I.IDEXEXNREP (exnInfo as {path, ty, used, loc, version})) => 
           let
             val exPath = case version of 
                            NONE => path
                          | SOME i => path @ [Int.toString i]
           in
             if PathSet.member(externSet, exPath) then
               (externSet, V.rebindId  (V.emptyEnv, name, I.IDEXEXNREP exnInfo), nil)
             else 
               let
                 val icdecl = I.ICEXTERNEXN ({path=exPath, ty=ty}, loc)
                 val externSet = PathSet.add(externSet, exPath)
               in
                 (externSet, V.rebindId  (V.emptyEnv, name, I.IDEXEXNREP exnInfo), [icdecl])
               end
           end
         | _ => 
           (EU.enqueueError
              (loc, E.ExceptionExpected("EI-150", {longid = path}));
            (externSet, V.emptyEnv, nil))
        )

      | PI.PISTRUCTURE {strid, strexp, loc} =>
        let
          val (externSet, newEnv, icdecls) = evalPistr (path@[strid]) topEnv (externSet, strexp)
          val strKind = V.STRENV (StructureID.generate())
          val env = V.rebindStr (V.emptyEnv, strid, {env=newEnv, strKind=strKind})
        in
          (externSet, env, icdecls)
        end
          
  and evalPistr path topEnv (externSet, pistrexp) = 
      case pistrexp of
        PI.PISTRUCT {decs, loc} =>
        let
          val (externSet, env, icdecls) = 
              foldl
                (fn (decl, (externSet, env, icdecls)) =>
                    let
                      val evalTopEnv = V.topEnvWithEnv (topEnv,env)
                      val (externSet, newEnv, newicdecls) = evalPidec path evalTopEnv (externSet, decl)
                    in
                      (externSet, V.unionEnv "210" loc (env, newEnv), icdecls@newicdecls)
                    end
                )
                (externSet, V.emptyEnv, nil)
                decs
        in
          (externSet, env, icdecls)
        end
      | PI.PISTRUCTREP{strPath, loc} => 
        let
          val {Env,...} = topEnv
        in
          case V.findStr(Env, strPath) of
            NONE => 
            (
             EU.enqueueError
               (loc, E.ExceptionNameUndefined("EI-140", {longid = path}));
             (externSet, V.emptyEnv, nil)
            )
          | SOME {env, strKind} => 
            (externSet, env, nil)
        end
      | PI.PIFUNCTORAPP{functorName, argumentPath, loc} => 
        let
          val {Env, FunE,...} = topEnv
        in
          case (SEnv.find(FunE, functorName), V.findStr(Env, argumentPath)) of
            (NONE, _) => 
            (EU.enqueueError
               (loc, E.FunctorNameUndefined("EI-140", {string = functorName}));
             (externSet, V.emptyEnv, nil))
          | (_, NONE) => 
            (EU.enqueueError
               (loc, E.StructureNameUndefined("EI-140", {longid = argumentPath}));
             (externSet, V.emptyEnv, nil))
          | (SOME funEEntry, SOME {env=argStrEnv, strKind}) =>
            let
              val {id,version, used,argSig,argStrName,argStrEntry,dummyIdfunArgTy,polyArgTys,
                   typidSet,exnIdSet,bodyEnv,bodyVarExp} = funEEntry
              fun instVarE (varE,actualVarE) {tvarS, tfvS, conIdS, exnIdS} =
                let
                  val conIdS =
                        SEnv.foldri
                          (fn (name, idstatus, conIdS) =>
                              case idstatus of
                                I.IDCON {id, ty} =>
                                (case SEnv.find(actualVarE, name) of
                                   SOME (idstatus as I.IDCON _) =>
                                   ConID.Map.insert(conIdS, id, idstatus)
                                 | SOME actualIdstatus => raise bug "non conid"
                                 | NONE => raise bug "conid not found in instVarE"
                                )
                              | _ => conIdS)
                          conIdS
                          varE
                  in
                    {tvarS=tvarS,tfvS=tfvS,exnIdS=exnIdS, conIdS=conIdS}
                  end
              fun instTfun path (tfun, actualTfun)
                           (subst as {tvarS, tfvS, conIdS, exnIdS}) =
                  let
                    val tfun = I.derefTfun tfun
                    val actualTfun = I.derefTfun actualTfun
                  in
                    case tfun of
                      I.TFUN_VAR (tfv1 as ref (I.TFUN_DTY {dtyKind,...})) =>
                      (case actualTfun of
                         I.TFUN_VAR(tfv2 as ref (tfunkind as I.TFUN_DTY _)) =>
                         (tfv1 := tfunkind;
                          {tfvS=TfvMap.insert (tfvS, tfv1, tfv2)
                           handle e => raise e,
                           tvarS=tvarS,
                           exnIdS=exnIdS,
                           conIdS=conIdS}
                         )
                       | I.TFUN_DEF _ =>
                         (case dtyKind of
                            I.FUNPARAM => 
                            (EU.enqueueError
                               (loc, E.FunctorParamRestriction("440",{longid=path}));
                             subst)
                          | _ => raise bug "tfun def"
                         )
                       | I.TFUN_VAR _ => raise bug "tfun var"
                      )
                    | I.TFUN_DEF{iseq, formals=nil, realizerTy= I.TYVAR tvar} =>
                      let
                        val ty =I.TYCONSTRUCT{typ={tfun=actualTfun,path=path},args=nil}
                        val ty = N.reduceTy TvarMap.empty ty
                      in
                        {tvarS=TvarMap.insert(tvarS,tvar,ty),
                         tfvS=tfvS,
                         conIdS=conIdS,
                         exnIdS=exnIdS
                        }
                      end
                    | _ => subst
                  end
              fun instTstr 
                    path (tstr, actualTstr)
                    (subst as {tvarS,tfvS,conIdS, exnIdS}) =
                  (
                   case tstr of
                     V.TSTR tfun =>
                     (
                      case actualTstr of
                        V.TSTR actualTfun =>
                        instTfun path (tfun, actualTfun) subst
                      | V.TSTR_DTY {tfun=actualTfun,...} =>
                        instTfun path (tfun, actualTfun) subst
                     )
                   | V.TSTR_DTY {tfun,varE,...} =>
                     (
                      case actualTstr of
                        V.TSTR actualTfun => raise bug "TSTR_DTY vs TST"
                      | V.TSTR_DTY {tfun=actualTfun,varE=actualVarE,...} =>
                        let
                          val subst = instTfun path (tfun, actualTfun) subst
                        in
                          instVarE (varE, actualVarE) subst
                        end
                     )
                  )
              fun instTyE path (tyE, actualTyE) subst =
                  SEnv.foldri
                    (fn (name, tstr, subst) =>
                        let
                          val actualTstr = 
                              case SEnv.find(actualTyE, name) of
                                SOME tstr => tstr
                              | NONE =>
                                (
                                 raise bug "tstr not found"
                                )
                        in
                          instTstr (path@[name]) (tstr, actualTstr) subst
                        end
                    )
                    subst
                    tyE
              fun instEnv path (argEnv, actualArgEnv) subst =
                  let
                    val V.ENV{tyE, strE,...} = argEnv
                    val V.ENV{tyE=actualTyE,strE=actualStrE,...} = actualArgEnv
                    val subst = instTyE path (tyE, actualTyE) subst
                    val subst = instStrE path (strE, actualStrE) subst
                  in
                    subst
                  end
              and instStrE path (V.STR envMap, V.STR actualEnvMap) subst =
                  SEnv.foldri
                    (fn (name, {env, strKind}, subst) =>
                        let
                          val actualEnv = case SEnv.find(actualEnvMap, name) of
                                            SOME {env,strKind} => env 
                                          | NONE => raise bug "actualEnv not found"
                        in
                          instEnv (path@[name]) (env, actualEnv) subst
                        end
                    )
                    subst
                    envMap
              val ((actualArgEnv, actualArgDecls), argId) =
                  let
                    val argSig = #2 (Sig.refreshSpecEnv argSig)
                        handle e => raise e
                    val argId = case strKind of
                                  V.STRENV id => id
                                | V.FUNAPP{id,...} => id
                                | _ => raise bug "non strenv in functor arg"
                  in
                    (SC.sigCheck
                       {mode = SC.Trans,
                        strPath = argumentPath,
                        strEnv = argStrEnv,
                        specEnv = argSig,
                        loc = loc
                       },
                     argId
                    )
                    handle e => raise e
                  end
              val _ = if EU.isAnyError () then raise SC.SIGCHECK else ()
              val tempEnv =
                  V.ENV{varE=SEnv.empty,
                        tyE=SEnv.empty,
                        strE=
                        V.STR
                          (
                           SEnv.insert
                             (SEnv.insert(SEnv.empty, "arg", argStrEntry),
                              "body",
                              {env=bodyEnv, strKind=V.STRENV(StructureID.generate())})
                          )
                       }
              val exnIdSubst = 
                  ExnID.Set.foldr
                    (fn (id, exnIdSubst) =>
                        let
                          val newId = ExnID.generate()
                        in
                          ExnID.Map.insert(exnIdSubst, id, newId)
                        end
                    )
                    ExnID.Map.empty
                    exnIdSet
              val ((tfvSubst, conIdSubst), tempEnv) =
                  SC.refreshEnv (typidSet, exnIdSubst) tempEnv
                  handle e => raise e
              val typIdSubst =
                  TfvMap.foldri
                    (fn (tfv1, tfv2, typIdSubst) =>
                        let
                          val id1 = L.getId tfv1 
                          val id2 = L.getId tfv2
                        in
                          TypID.Map.insert(typIdSubst, id1, id2)
                        end
                    )
                    TypID.Map.empty
                    tfvSubst
              val typidSet =
                  TypID.Set.map
                    (fn id => case TypID.Map.find(typIdSubst, id) of
                                SOME id => id
                              | NONE => id)
                    typidSet
              val {env=argEnv, strKind} = 
                  case V.findStr(tempEnv, ["arg"]) of
                    SOME strEntry => strEntry
                  | NONE => raise bug "impossible"
              val {env=bodyEnv, ...} = 
                  case V.findStr(tempEnv, ["body"]) of
                    SOME env => env
                  | NONE => raise bug "impossible"
              val subst = instEnv nil (argEnv, actualArgEnv) S.emptySubst
              val bodyEnv = S.substEnv subst bodyEnv
                  handle e => raise e
              val bodyEnv = N.reduceEnv bodyEnv 
                  handle e => raise e
              val (externSet, bodyEnv, icdecls) = genTypedExternVarsEnv loc path bodyEnv (externSet, nil)
            in
              (externSet, bodyEnv, icdecls)
            end
            handle SC.SIGCHECK => (externSet, V.emptyEnv, nil)
        end (* end of pidec *)
      handle exn => raise bug "uncaught exception in evalPistr"

  fun internalizeIdstatus (pathSet,idstatus) =
      case idstatus of
        I.IDEXEXN {path, ty, used, loc, version} =>
        if PathSet.member(pathSet, path) then (pathSet, idstatus)
        else
          let
            val pathSet = PathSet.add(pathSet, path)
            val newId = ExnID.generate() (* dummy *)
          in
            (pathSet, I.IDEXN {id=newId, ty= ty})
          end
      | _ => (pathSet, idstatus)

  fun internalizeEnv (pathSet, V.ENV {tyE, varE, strE=V.STR envMap}) =
      let
        val (pathSet, varE) = 
            SEnv.foldri
              (fn (name, idstatus, (pathSet, varE)) =>
                  let
                    val (pathSet, idstatus)=  internalizeIdstatus (pathSet, idstatus)
                    val varE = SEnv.insert(varE, name, idstatus)
                  in
                    (pathSet, varE)
                  end
              )
              (pathSet, SEnv.empty)
              varE
        val (pathSet, strE) = 
            let
              val (pathSet, envMap) =
                  SEnv.foldri
                    (fn (name, {env, strKind}, (pathSet, envMap)) => 
                        let
                          val (pathSet, env) = internalizeEnv (PathSet.empty, env)
                          val envMap = SEnv.insert(envMap, name, {env=env, strKind=strKind})
                        in
                          (pathSet, envMap)
                        end
                    )
                    (pathSet, SEnv.empty)
                    envMap
            in
              (pathSet, V.STR envMap)
            end
      in
        (pathSet, V.ENV{tyE=tyE, varE=varE, strE=strE})
      end
  val internalizeEnv = fn env => #2 (internalizeEnv (PathSet.empty, env))
  fun evalFunDecl topEnv {funid=functorName,
                          param={strid=argStrName, sigexp=argSig},
                          strexp=bodyStr, loc} =
      let
        val 
        {
         argSig=argSig,
         argStrEntry=argStrEntry,
         extraTvars=extraTvars,
         polyArgPats=polyArgPats,
         exnTagDecls=exnTagDecls,
         dummyIdfunArgTy=dummyIdfunArgTy,
         firstArgPat=firstArgPat,
         tfvDecls = tfvDecls
        } = FunctorUtils.evalFunArg (topEnv, argSig, loc)

        val topArgEnv = V.ENV {varE=SEnv.empty,
                               tyE=SEnv.empty,
                               strE=V.STR (SEnv.singleton(argStrName, argStrEntry))
                              }
        val evalEnv = V.topEnvWithEnv (topEnv, topArgEnv)

        val startTypid = TypID.generate()

        val (_, bodyInterfaceEnv,_) = evalPistr nil evalEnv (PathSet.empty, bodyStr)
(*
        val (_, bodyInterfaceEnv,_) = evalPistr [functorName] evalEnv (PathSet.empty, bodyStr)
*)
        val bodyEnv = internalizeEnv bodyInterfaceEnv

        val
        {
         allVars = allVars,
         typidSet = typidSet,
         exnIdSet = exnIdSet
        } = FunctorUtils.makeBodyEnv bodyEnv loc

        (* FIXME (not a bug):
           The following is to restrict the typids to be refreshed
           are those that are created in the functor body.
           Not very elegant. Need to review.
         *)
        val typidSet =
            TypID.Set.filter
            (fn id => 
                case TypID.compare(id, startTypid) of
                  GREATER => true
                | _ => false)
            typidSet

        fun varToTy (_,var) =
            case var of
              I.ICEXVAR ({path, ty},_) => ty
            | I.ICEXN ({path, id, ty},_) => ty
            | I.ICEXN_CONSTRUCTOR ({id, ty, path}, loc) => BV.exntagTy
            | _ => 
              (
               raise bug "*** VARTOTY ***"
              )

        val bodyTy =
            case allVars of
              nil => BV.unitTy
            | _ => I.TYRECORD (Utils.listToFields (map varToTy allVars))
        val polyArgTys = map (fn (x,ty) => ty) polyArgPats 
        val firstArgTy =
            case dummyIdfunArgTy of
              SOME ty => SOME(I.TYFUNM([ty],ty))
            | NONE => NONE
        val functorTy1 =
            case polyArgTys of
              nil => bodyTy
            | _ => I.TYFUNM(polyArgTys, bodyTy)
        val functorTy2 =
            case firstArgTy of
              NONE => functorTy1
            | SOME ty  => 
              I.TYPOLY(map (fn x => (x, I.UNIV)) extraTvars,
                        I.TYFUNM([ty], functorTy1))
        val functorTy =
            case functorTy2 of
              I.TYPOLY _ => functorTy2
            | I.TYFUNM _ => functorTy2
            | _ => I.TYFUNM([BV.unitTy], functorTy2)

        val decl =
            I.ICEXTERNVAR ({path=[FUNCORPREFIX,functorName], ty=functorTy},
                           loc)
                   
        val functorExp = I.ICEXVAR ({path=[FUNCORPREFIX,functorName],
                                     ty=functorTy}, loc)

        val funEEntry:V.funEEntry =
            {id = FunctorID.generate(),
             version = NONE,
             used = ref false,
             argSig = argSig,
             argStrName = argStrName,
             argStrEntry = argStrEntry,
             dummyIdfunArgTy = dummyIdfunArgTy,
             polyArgTys = polyArgTys,
             typidSet=typidSet,  (* FIXME: is this right? *)
             exnIdSet=exnIdSet,  (* FIXME: is this right? *)
             bodyEnv = bodyEnv,
             bodyVarExp = functorExp
            }
            
        val funE =  SEnv.singleton(functorName, funEEntry)
        val returnTopEnv = V.topEnvWithFunE(V.emptyTopEnv, funE)
      in
        (returnTopEnv, [decl])
      end

  fun evalPitopdec topEnv (externSet, pitopDec) =
      case pitopDec of
        PI.PIDEC pidec => 
        let
          val (_, returnEnv, icdecls) = evalPidec nilPath topEnv (externSet, pidec)
        in
          (externSet, V.topEnvWithEnv(V.emptyTopEnv, returnEnv), icdecls)
        end
      | PI.PIFUNDEC fundec =>
        let
          val (returnTopEnv, icdecls) = evalFunDecl topEnv fundec
        in
          (externSet, returnTopEnv, icdecls)
        end

  fun evalPitopdecList topEnv (externSet, pitopdecList) =
      (foldl
         (fn (pitopdec, (externSet, returnTopEnv, icdecls)) =>
             let
               val evalTopEnv = V.topEnvWithTopEnv (topEnv, returnTopEnv)
               val (externSet, newTopEnv, newicdecls) = evalPitopdec evalTopEnv (externSet, pitopdec)
               val loc = PI.pitopdecLoc pitopdec
             in
               (externSet, V.unionTopEnv "211" loc (returnTopEnv,newTopEnv), icdecls @ newicdecls)
             end
         )
         (externSet, V.emptyTopEnv, nil)
         pitopdecList
      )
      handle exn => raise bug "uncaught exception in evalPitopdecList"

  fun evalInterfaceDec env ({interfaceId,requires=idLocList,topdecs,...}
                            :PI.interfaceDec, IntEnv) =
      let
        val evalTopEnv =
            foldl
            (fn ({id,loc}, evalTopEnv) =>
                let
                  val newTopEnv = 
                      case InterfaceID.Map.find (IntEnv, id) of
                        NONE => raise bug "InterfaceID undefined"
                      | SOME {topEnv,...} => topEnv
                in
                  V.unionTopEnv "212" loc (evalTopEnv, newTopEnv)
                end
            )
            env
            idLocList
        val (_, topEnv, icdecls) = evalPitopdecList evalTopEnv (PathSet.empty, topdecs)
      in
        case InterfaceID.Map.find(IntEnv, interfaceId) of
          NONE => InterfaceID.Map.insert
                    (IntEnv,
                     interfaceId,
                     {source=topdecs, topEnv=topEnv, decls=icdecls}
                    )
        | SOME _ => raise bug "duplicate interfaceid"
      end

  fun evalInterfaces env interfaceDecList =
      foldl (evalInterfaceDec env) InterfaceID.Map.empty interfaceDecList
      handle exn => raise bug "uncaught exception in evalInterfaces"
end
end
