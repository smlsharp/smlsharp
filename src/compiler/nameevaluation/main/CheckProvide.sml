(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
(* the initial error code of this file : CP-001 *)
structure CheckProvide :
sig
  val checkPitopdecList : 
      NameEvalEnv.topEnv
      -> (NameEvalEnv.topEnv * PatternCalcInterface.pitopdec list)
      -> IDCalc.icdecl list
end
=
struct
local
  structure I = IDCalc
  structure V = NameEvalEnv
  structure BV = BuiltinEnv
  structure PI = PatternCalcInterface
  structure U = NameEvalUtils
  structure EU = UserErrorUtils
  structure E = NameEvalError
  structure A = AbsynInterface
  structure N = NormalizeTy
  structure Ty = EvalTy
  structure Sig = EvalSig
  structure FU = FunctorUtils
  structure EI = NameEvalInterface
  val nilPath = nil
  fun bug s = Control.Bug ("CheckProvide: " ^ s)
  exception Fail

  fun genTypedExportVarsIdstatus loc path idstatus (exnSet, icdecls) =
      case idstatus of
        I.IDVAR varId => (exnSet, I.ICEXPORTTYPECHECKEDVAR ({path=path, id=varId}, loc) :: icdecls)
      | I.IDVAR_TYPED {id=varId,ty} => 
        (exnSet, I.ICEXPORTTYPECHECKEDVAR ({path=path, id=varId}, loc) :: icdecls)
      | I.IDEXVAR {path, ty, used, loc, version, internalId} => (exnSet, icdecls)
      | I.IDEXVAR_TOBETYPED _ => raise bug "IDEXVAR_TOBETYPED"
      | I.IDBUILTINVAR {primitive, ty} => (exnSet, icdecls)
      | I.IDCON {id, ty} => (exnSet, icdecls)
      | I.IDEXN {id, ty} => 
        if not (ExnID.Set.member(exnSet, id)) then
          (ExnID.Set.add(exnSet, id), 
           I.ICEXPORTEXN ({path=path, ty=ty, id=id}, loc) :: icdecls)
        else (exnSet, icdecls)
      | I.IDEXNREP {id, ty} => 
        if not (ExnID.Set.member(exnSet, id)) then
          (ExnID.Set.add(exnSet, id), 
           I.ICEXPORTEXN ({path=path, ty=ty, id=id}, loc) :: icdecls)
        else (exnSet, icdecls)
      | I.IDEXEXN {path, ty, used, loc, version} => (exnSet, icdecls)
      | I.IDEXEXNREP {path, ty, used, loc, version} => (exnSet, icdecls)
      | I.IDOPRIM {id, overloadDef, used, loc} => (exnSet, icdecls)
      | I.IDSPECVAR ty => raise bug "IDSPECVAR in genTypedExportVars"
      | I.IDSPECEXN ty => raise bug "IDSPECEXN in genTypedExportVars"
      | I.IDSPECCON  => raise bug "IDSPECCON in genTypedExportVars"
  fun genTypedExportVarsVarE loc path varE (exnSet,icdecls) =
      SEnv.foldli
      (fn (name, idstatus, (exnSet, icdecls)) =>
          genTypedExportVarsIdstatus loc (path@[name]) idstatus (exnSet, icdecls))
      (exnSet, icdecls)
      varE
  fun genTypedExportVarsEnv loc path (V.ENV{varE, tyE, strE}) (exnSet,icdecls) =
      let
        val (exnSet, icdecls) = genTypedExportVarsVarE loc path varE (exnSet, icdecls)
        val (exnSet, icdecls) = genTypedExportVarsStrE loc path strE (exnSet, icdecls)
      in
        (exnSet, icdecls)
      end
  and genTypedExportVarsStrE loc path (V.STR strEntryMap) (exnSet,icdecls) =
      SEnv.foldli
      (fn (name, {env, strKind}, (exnSet,icdecls)) =>
          genTypedExportVarsEnv loc (path@[name]) env (exnSet,icdecls)
      )
      (exnSet, icdecls)
      strEntryMap

  fun checkDatbind
        loc
        path
        evalEnv
        env
        (name,defTstr,defRealTstr,defRealTfun, {tyvars, tycon, conbind}) 
    =
    (* datatype 'a foo = FOO of 'a | BAR  *)
    let
      val (tvarEnv, tvarList) = Ty.genTvarList Ty.emptyTvarEnv tyvars
    in
      let
        val {id, iseq, formals, conSpec, dtyKind,...} =
            case I.derefTfun defRealTfun of 
              I.TFUN_DEF _ =>
              (EU.enqueueError
                 (loc,E.ProvideDtyExpected ("CP-010",{longid=path@[tycon]}));
               raise Fail)
            | I.TFUN_VAR(ref(I.TFUN_DTY x)) => x
            | _ =>
              (EU.enqueueError
                 (loc,E.ProvideDtyExpected ("CP-020",{longid=path@[tycon]}));
               raise Fail)
        val eqEnv =
            if length tvarList = length formals then
              let
                val tvarPairs = ListPair.zip (tvarList, formals)
              in
                foldr
                  (fn (({id=tv1,...}, {id=tv2,...}), eqEnv) =>
                      TvarID.Map.insert(eqEnv, tv1, tv2)
                  )
                  TvarID.Map.empty
                  tvarPairs
              end
            else
              (EU.enqueueError
                 (loc, E.ProvideArity("CP-030",{longid = path@[tycon]}));
               raise Fail
              )
        val (nameTyPairList, conSpec) =
            foldr
              (fn ({vid, ty}, (nameTyPairList, conSpec)) =>
                  let
                    val ty =
                        Option.map 
                          (Ty.evalTy tvarEnv evalEnv)
                          ty
                          handle e => raise e                          
                    val (actualTyOpt, conSpec) = 
                        case SEnv.find(conSpec, vid) of
                          NONE =>
                          (EU.enqueueError
                             (loc,
                              E.ProvideUndefinedCon
                                ("CP-040",{longid=path@[vid]}));
                           raise Fail
                          )
                        | SOME tyOpt => 
                          (tyOpt, #1 (SEnv.remove(conSpec, vid))
                                  handle LibBase.NotFound => raise bug "SEnv.remove"
                          )
                  in
                    ((vid, ty, actualTyOpt)::nameTyPairList, conSpec)
                  end
              )
              (nil, conSpec)
              conbind
        val _ = 
            SEnv.appi
              (fn (name, _) => 
                  EU.enqueueError
                    (loc,
                     E.ProvideRedundantCon("CP-050",{longid=path@[name]}))
              )
              conSpec
        val _ = if SEnv.isEmpty conSpec then () 
                else raise Fail
        val _ = 
            List.app
              (fn (name, tyOpt1, tyOpt2) =>
                  case (tyOpt1, tyOpt2) of
                    (NONE, NONE) => ()
                  | (SOME ty1, SOME ty2) => 
                    if N.equalTy (N.emptyTypIdEquiv, eqEnv) (ty1, ty2) then ()
                    else 
                      (EU.enqueueError
                         (loc,
                          E.ProvideConType("CP-060",{longid=path@[name]}));
                       raise Fail)
                  | _ => 
                    (EU.enqueueError
                       (loc,
                        E.ProvideConType("CP-070",{longid = path@[name]}));
                     raise Fail)
              )
              nameTyPairList
      in
        V.rebindTstr (V.emptyEnv, tycon, defTstr)
      end
    end
      
  fun checkDatbindList loc path evalEnv env datbinds =
      let
        val nameTstrTfunDatbindList =
            foldr
              (fn (datbind as {tyvars, tycon, conbind},
                   nameTstrTfunDatbindList) =>
                  let
                    val defTstr = 
                        case V.findTstr(env, [tycon]) of
                          NONE => (EU.enqueueError
                                     (loc,
                                      E.ProvideUndefinedTypeName
                                        ("CP-080",{longid = path@[tycon]}));
                                   raise Fail)
                        | SOME tstr => tstr
                    val (defTfun, varE) = 
                        case defTstr of
                          V.TSTR tfun => (tfun, SEnv.empty)
                        | V.TSTR_DTY {tfun, varE,...} => (I.derefTfun tfun, varE)

                    val (conSpec, formals) = 
                        case I.derefTfun defTfun of
                          I.TFUN_VAR(ref (I.TFUN_DTY{formals, conSpec,...})) =>
                          (conSpec, formals)
                        | _ => 
                          (EU.enqueueError
                             (loc,E.ProvideDtyExpected
                                    ("CP-090",{longid=path@[tycon]}));
                           raise Fail)
                    val defRealTstr =
                        V.TSTR_DTY{tfun=defTfun,
                                   varE = varE,
                                   formals=formals,
                                   conSpec=conSpec}
                  in
                    (tycon, defTstr, defRealTstr, defTfun, datbind)::
                    nameTstrTfunDatbindList
                  end
              )
              nil
              datbinds
        val evalEnv =
            foldl
              (fn ((name, defTstr, defRealTstr, tfun, dtbind), evalEnv) =>
                  V.rebindTstr(evalEnv, name, defRealTstr))
              evalEnv
              nameTstrTfunDatbindList
      in
        foldl
          (fn (nameTstrTfunBind, returnEnv) => 
              let
                val newEnv =
                    checkDatbind loc path evalEnv env nameTstrTfunBind
              in
                V.unionEnv "CP-100" loc (returnEnv, newEnv)
              end
          )
          V.emptyEnv
          nameTstrTfunDatbindList
      end

  fun checkPidec exnSet path (evalTopEnv as {Env=evalEnv,FunE, SigE}) (env, pidec) =
      case pidec of
        PI.PIVAL {scopedTvars, vid=name, body, loc} =>
        let
          val internalPath = path@[name] (* for declaration and error message *)
          val (tvarEnv, scopedTvars) =
              Ty.evalScopedTvars loc Ty.emptyTvarEnv evalEnv scopedTvars
          fun processExternVal {externPath, ty} =
            let
              val ty = Ty.evalTy tvarEnv evalEnv ty handle e => raise e
              val ty = case scopedTvars of
                         nil => ty
                       | _ => I.TYPOLY(scopedTvars, ty)
            in
              case V.findId(env, [name]) of
                NONE =>
                (EU.enqueueError
                   (loc, E.ProvideUndefinedID("CP-110", {longid = internalPath}));
                 raise Fail)
              | SOME (idstatus as I.IDVAR varid) =>
                (exnSet,
                 V.rebindId(V.emptyEnv,name,idstatus),
                 [I.ICEXPORTVAR ({id=varid, path=externPath}, ty, loc)]
                )
              | SOME (idstatus as I.IDVAR_TYPED {id=varid, ty=varTy}) =>
                if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty, varTy) then
                  (exnSet,
                   V.rebindId(V.emptyEnv,name,idstatus),
                   [I.ICEXPORTTYPECHECKEDVAR ({id=varid, path=externPath}, loc)]
                  )
                else
                  (EU.enqueueError
                     (loc, E.ProvideIDType("CP-120", {longid = internalPath}));
                   raise Fail)
              | SOME (idstatus as I.IDEXVAR {path=exVarPath, ty, used, loc, version, internalId}) =>
                (* bug 069_open *)
                (* bug 124_open *)
                let
                  val _ = used := true
                  val icexp  =I.ICEXVAR ({path=exVarPath,ty=ty},loc)
                  val newId = VarID.generate()
                  val icpat = I.ICPATVAR ({path=internalPath,id=newId},loc)
                  val valDecl = 
                      I.ICVAL(Ty.emptyScopedTvars,[(icpat,icexp)],loc)
                  val icdecls = 
                      [valDecl,
                       I.ICEXPORTVAR({id=newId,path=externPath},ty,loc)]
                in
                  (exnSet,
                   V.rebindId(V.emptyEnv,name,idstatus),
                   icdecls
                  )
                end
              | SOME (I.IDEXVAR_TOBETYPED _) => raise bug "IDEXVAR_TOBETYPED"
              | SOME (idstatus as I.IDBUILTINVAR {primitive, ty}) =>
                (* bug 075_builtin *)
                let
                  val icexp = I.ICBUILTINVAR{primitive=primitive,ty=ty,loc=loc}
                  val newId = VarID.generate()
                  val icpat = I.ICPATVAR ({path=internalPath,id=newId},loc)
                  val valDecl = 
                      I.ICVAL(Ty.emptyScopedTvars,[(icpat,icexp)],loc)
                  val icdecls = 
                      [valDecl,
                       I.ICEXPORTVAR({id=newId,path=externPath},ty,loc)]
                in
                  (exnSet,
                   V.rebindId(V.emptyEnv,name,idstatus),
                   icdecls)
                end

              | SOME (idstatus as I.IDCON {id=conId, ty}) =>
                let
                  val icexp  =I.ICCON ({path=internalPath,ty=ty, id=conId},loc)
                  val newId = VarID.generate()
                  val icpat = I.ICPATVAR ({path=internalPath,id=newId},loc)
                  val valDecl = 
                      I.ICVAL(Ty.emptyScopedTvars,[(icpat,icexp)],loc)
                  val icdecls = 
                      [valDecl,
                       I.ICEXPORTVAR({id=newId,path=externPath},ty,loc)]
                in
                  (exnSet,
                   V.rebindId(V.emptyEnv,name,idstatus),
                   icdecls)
                end
              | SOME (idstatus as I.IDEXN {id, ty}) =>
                let
                  val icexp  =I.ICEXN ({path=internalPath,ty=ty,id=id}, loc)
                  val newId = VarID.generate()
                  val icpat = I.ICPATVAR ({path=internalPath,id=newId},loc)
                  val valDecl = 
                      I.ICVAL(Ty.emptyScopedTvars,[(icpat,icexp)],loc)
                in
                  (exnSet,
                   V.rebindId(V.emptyEnv,name,idstatus),
                   [valDecl])
                end
              | SOME (idstatus as I.IDEXNREP {id, ty}) =>
                let
                  val icexp  =I.ICEXN ({path=internalPath,ty=ty,id=id}, loc)
                  val newId = VarID.generate()
                  val icpat = I.ICPATVAR ({path=internalPath,id=newId},loc)
                  val valDecl = 
                      I.ICVAL(Ty.emptyScopedTvars,[(icpat,icexp)],loc)
                  val icdecls = 
                      [valDecl,
                       I.ICEXPORTVAR ({id=newId,path=externPath},ty, loc)]
                in
                  (exnSet, V.rebindId(V.emptyEnv,name,idstatus), icdecls)
                end
              | SOME (I.IDEXEXN {path, ty, used, loc, version}) => raise bug "IDEXEXN in env"
              | SOME (I.IDEXEXNREP {path, ty, used, loc, version}) => raise bug "IDEXEXN in env"
              | SOME (I.IDOPRIM {id, overloadDef, used, loc}) => raise bug "IDOPRIM in env"
              | SOME (I.IDSPECVAR _) => raise bug "IDSPECVAR in provideEnv"
              | SOME (I.IDSPECEXN _ ) => raise bug "IDSPECEXN in provideEnv"
              | SOME I.IDSPECCON => raise bug "IDSPECCON in provideEnv"
            end
        in
          case body of
            A.VAL_EXTERN {ty} => processExternVal {externPath=internalPath, ty=ty}
          | A.VAL_EXTERN_WITHNAME {ty, externPath} => processExternVal {externPath=externPath, ty=ty}
          | A.VALALIAS_EXTERN {path=aliasPath} =>
            (case V.findId(env, [name]) of
                NONE =>
                (EU.enqueueError
                   (loc, E.ProvideUndefinedID("CP-130", {longid = [name]}));
                 raise Fail)
              | SOME (idstatus as I.IDEXVAR {path=refPath, ty, used=used1, loc, version, internalId}) =>
                (case V.findId(evalEnv, aliasPath) of
                   SOME (idstatus as I.IDEXVAR {path=defPath, ty, used=used2, loc, version, internalId}) =>
                   if refPath = defPath then
                     (used1 := true; used2:=true;
                      (exnSet, V.rebindId(V.emptyEnv,name,idstatus), nil)
                     )
                   else 
                   (EU.enqueueError
                      (loc, E.ProvideVariableAlias("CP-140", {longid = internalPath}));
                    raise Fail)
                 | SOME _ =>
                   (EU.enqueueError
                      (loc, E.ProvideVariableAlias("CP-150", {longid = internalPath}));
                    raise Fail)
                 | NONE =>
                   (EU.enqueueError
                      (loc, E.ProvideUndefinedID("CP-160", {longid = internalPath}));
                    raise Fail)
                   )
              | SOME (idstatus as I.IDBUILTINVAR {primitive=refPrim, ...}) =>
                (case V.findId(evalEnv, aliasPath) of
                   SOME (I.IDBUILTINVAR {primitive=defPrim, ...}) =>
                   if refPrim = defPrim then
                     (exnSet, V.rebindId(V.emptyEnv,name,idstatus), nil)
                   else
                     (EU.enqueueError
                        (loc, E.ProvideVariableAlias("CP-170", {longid = internalPath}));
                      raise Fail)
                 | SOME _ =>
                   (EU.enqueueError
                      (loc, E.ProvideVariableAlias("CP-180", {longid = internalPath}));
                    raise Fail)
                 | NONE =>
                   (EU.enqueueError
                      (loc, E.ProvideUndefinedID("CP-190", {longid = internalPath}));
                    raise Fail)
                   )
              | SOME (idstatus as (I.IDVAR refId)) =>
                (case V.findId(evalEnv, aliasPath) of
                   SOME (idstatus as (I.IDVAR defId)) =>
                   if VarID.eq(refId,defId) then
                     (exnSet, V.rebindId(V.emptyEnv,name,idstatus), nil)
                   else 
                   (EU.enqueueError
                      (loc, E.ProvideVariableAlias("CP-200", {longid = internalPath}));
                    raise Fail)
                 | SOME (idstatus as (I.IDVAR_TYPED {id=defId, ty})) =>
                   if VarID.eq(refId,defId) then
                     (exnSet, V.rebindId(V.emptyEnv,name,idstatus), nil)
                   else 
                   (EU.enqueueError
                      (loc, E.ProvideVariableAlias("CP-201", {longid = internalPath}));
                    raise Fail)
                 | SOME _ =>
                   (EU.enqueueError
                      (loc, E.ProvideVariableAlias("CP-210", {longid = internalPath}));
                    raise Fail)
                 | NONE =>
                   (EU.enqueueError
                      (loc, E.ProvideUndefinedID("CP-220", {longid = internalPath}));
                    raise Fail)
                   )
              | SOME (idstatus as (I.IDVAR_TYPED {id=refId, ty})) =>
                (case V.findId(evalEnv, aliasPath) of
                   SOME (idstatus as (I.IDVAR defId)) =>
                   if VarID.eq(refId,defId) then
                     (exnSet, V.rebindId(V.emptyEnv,name,idstatus), nil)
                   else 
                   (EU.enqueueError
                      (loc, E.ProvideVariableAlias("CP-200", {longid = internalPath}));
                    raise Fail)
                 | SOME (idstatus as (I.IDVAR_TYPED {id=defId, ty})) =>
                   if VarID.eq(refId,defId) then
                     (exnSet, V.rebindId(V.emptyEnv,name,idstatus), nil)
                   else 
                   (EU.enqueueError
                      (loc, E.ProvideVariableAlias("CP-201", {longid = internalPath}));
                    raise Fail)
                 | SOME _ =>
                   (EU.enqueueError
                      (loc, E.ProvideVariableAlias("CP-210", {longid = internalPath}));
                    raise Fail)
                 | NONE =>
                   (EU.enqueueError
                      (loc, E.ProvideUndefinedID("CP-220", {longid = internalPath}));
                    raise Fail)
                   )
              | SOME _ =>
                (EU.enqueueError
                   (loc, E.ProvideVarIDExpected("CP-230", {longid = internalPath}));
                 raise Fail)
            )
          | A.VAL_BUILTIN {builtinName, ty} =>
            raise bug "VAL_BUILTIN in provideSpec"
          | A.VAL_OVERLOAD overloadCase =>
            (exnSet, V.emptyEnv, nil)
        end

      | PI.PITYPE {tyvars, tycon=name, ty, loc} =>
       (* type 'a foo = ty  *)
        let
          val internalPath = path@[name]
          val _ = EU.checkNameDuplication
                    (fn {name, eq} => name)
                    tyvars
                    loc
                    (fn s => E.DuplicateTypParms("CP-240",s))
          val (tvarEnv, tvarList) = Ty.genTvarList Ty.emptyTvarEnv tyvars
          val ty = Ty.evalTy tvarEnv evalEnv ty handle e => raise e
          val tfunSpec =
              case N.tyForm tvarList ty of
                N.TYNAME {tfun,...} => tfun
              | N.TYTERM ty =>
                let
                  val iseq = N.admitEq tvarList ty
                in
                  I.TFUN_DEF {iseq=iseq,
                              formals=tvarList,
                              realizerTy=ty
                             }
                end
          val tstrDef =
              case V.findTstr(env, [name]) of
                NONE =>
                (EU.enqueueError
                   (loc,
                    E.ProvideUndefinedTypeName("CP-250",{longid = internalPath}));
                 raise Fail)
              | SOME tstr => tstr
          val tfunDef = 
              case tstrDef of
                V.TSTR tfun => I.derefTfun tfun
              | V.TSTR_DTY {tfun,...} => I.derefTfun tfun
          val _ =
              if N.equalTfun N.emptyTypIdEquiv (tfunSpec, tfunDef) then  ()
              else 
                (EU.enqueueError
                   (loc, E.ProvideInequalTfun("CP-260",{longid = internalPath}));
                 raise Fail)
        in
          (exnSet, V.rebindTstr (V.emptyEnv, name, tstrDef), nil)
        end

      | PI.PIOPAQUE_TYPE {tyvars, tycon=name, runtimeTy, loc} =>
       (* type 'a foo (= runtimeTy )  *)
        let
          val internalPath = path@[name]
          val _ = EU.checkNameDuplication
                    (fn {name, eq} => name)
                    tyvars
                    loc
                    (fn s => E.DuplicateTypParms("CP-270",s))
          val (tvarEnv, tvarList) = Ty.genTvarList Ty.emptyTvarEnv tyvars
          val tstrDef =
              case V.findTstr(env, [name]) of
                NONE =>
                (EU.enqueueError
                   (loc,
                    E.ProvideUndefinedTypeName("CP-280",{longid = internalPath}));
                 raise Fail)
              | SOME tstr => tstr
          val tfunDef = 
              case tstrDef of
                V.TSTR tfun => I.derefTfun tfun
              | V.TSTR_DTY {tfun,...} => I.derefTfun tfun
          val defRuntimeTy = 
              case I.tfunRuntimeTy tfunDef of
                SOME ty => ty
              | NONE => raise bug "tfunRuntimeTy"
          val _ =
              if BuiltinType.compatTy {absTy=runtimeTy, implTy=defRuntimeTy} then  ()
              else 
                (
                 EU.enqueueError
                   (loc, E.ProvideRuntimeType("CP-290",{longid = internalPath}));
                 raise Fail)
          val arity = I.tfunArity tfunDef
          val _ =
              if List.length tyvars = arity then  ()
              else 
                (EU.enqueueError
                   (loc, E.ProvideArity("CP-300",{longid = internalPath}));
                 raise Fail)
        in
          (exnSet, V.rebindTstr (V.emptyEnv, name, tstrDef), nil)
        end

      | PI.PIOPAQUE_EQTYPE {tyvars, tycon=name, runtimeTy, loc} =>
       (* eqtype 'a foo (= runtimeTy )  *)
        let
          val internalPath = path@[name]
          val _ = EU.checkNameDuplication
                    (fn {name, eq} => name)
                    tyvars
                    loc
                    (fn s => E.DuplicateTypParms("CP-310",s))
          val (tvarEnv, tvarList) = Ty.genTvarList Ty.emptyTvarEnv tyvars
          val tstrDef =
              case V.findTstr(env, [name]) of
                NONE =>
                (EU.enqueueError
                   (loc,
                    E.ProvideUndefinedTypeName("CP-320",{longid = internalPath}));
                 raise Fail)
              | SOME tstr => tstr
          val tfunDef = 
              case tstrDef of
                V.TSTR tfun => I.derefTfun tfun
              | V.TSTR_DTY {tfun,...} => I.derefTfun tfun
          val defRuntimeTy = 
              case I.tfunRuntimeTy tfunDef of
                SOME ty => ty
              | NONE => raise bug "tfunRuntimeTy"
          val _ =
              if BuiltinType.compatTy {absTy=runtimeTy, implTy=defRuntimeTy} then ()
              else 
                (
                 EU.enqueueError
                   (loc, E.ProvideRuntimeType("CP-330",{longid = internalPath}));
                 raise Fail)
          val arity = I.tfunArity tfunDef
          val _ =
              if List.length tyvars = arity then  ()
              else 
                (EU.enqueueError
                   (loc, E.ProvideArity("CP-340",{longid = internalPath}));
                 raise Fail)
          val iseq = I.tfunIseq tfunDef
          val _ = if iseq then ()
                  else
                (EU.enqueueError
                   (loc, E.ProvideEquality("CP-350",{longid = internalPath}));
                 raise Fail)
        in
          (exnSet, V.rebindTstr (V.emptyEnv, name, tstrDef), nil)
        end

      | PI.PITYPEBUILTIN {tycon, builtinName, loc} =>
        raise bug "PITYPEBUILTIN in provideSpec"

      | PI.PITYPEREP {tycon, origTycon, loc} =>
        (* datatype foo = datatype bar *)
         let
           val internalPath = path @ [tycon]
           val specTstr =
               case V.findTstr(evalEnv, origTycon) of
                 NONE => (EU.enqueueError
                            (loc,
                             E.ProvideUndefinedTypeName
                               ("CP-360",{longid = internalPath}));
                          raise Fail)
               | SOME tstr => tstr
           val specTfun =
               case specTstr of
                 V.TSTR tfun => I.derefTfun tfun
               | V.TSTR_DTY {tfun,...} => I.derefTfun tfun
           val defTstr = 
               case V.findTstr(env, [tycon]) of
                 NONE => (EU.enqueueError
                            (loc,
                             E.ProvideUndefinedTypeName
                               ("CP-370",{longid = internalPath}));
                          raise Fail)
               | SOME tstr => tstr
           val defTfun = 
               case defTstr of
                 V.TSTR tfun => I.derefTfun tfun
               | V.TSTR_DTY {tfun,...} => I.derefTfun tfun
         in
           if N.equalTfun N.emptyTypIdEquiv (defTfun, specTfun) then 
             let
               val returnEnv = V.rebindTstr(V.emptyEnv,tycon, defTstr)
             in
               (exnSet, returnEnv, nil)
             end
           else 
             (EU.enqueueError
                (loc,
                 E.ProvideDtyExpected ("CP-380",{longid = internalPath}));
              raise Fail)
         end

      | PI.PIEXCEPTION {vid=name, ty=tyOpt, externPath, loc} => 
        let
          val internalPath = path@[name]
          val externPath = case externPath of 
                             NONE => internalPath
                           | SOME path => path
          val tySpec =
              case tyOpt of 
                NONE => BV.exnTy
              | SOME ty => I.TYFUNM([Ty.evalTy Ty.emptyTvarEnv evalEnv ty],
                                    BV.exnTy)
                handle e => raise e
        in
          case V.findId (env, [name]) of
            NONE =>
            (EU.enqueueError
               (loc, E.ProvideUndefinedID("CP-390", {longid = internalPath}));
             raise Fail)
          | SOME (idstatus as I.IDEXN {id,ty}) => 
            if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty, tySpec) then
              (ExnID.Set.add(exnSet, id),
               V.rebindId(V.emptyEnv, name, idstatus),
               [I.ICEXPORTEXN ({id=id,ty=ty,path=externPath},loc)]
              )
            else 
              (EU.enqueueError
                 (loc, E.ProvideExceptionType("CP-400", {longid = path}));
               raise Fail)
          | SOME (I.IDEXNREP {id,ty}) =>
            (* BUG 128_functor.sml *)
            if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty, tySpec)
            then
              if not (ExnID.Set.member(exnSet, id)) then
                (ExnID.Set.add(exnSet, id),
                 V.rebindId(V.emptyEnv, name, I.IDEXN {id=id, ty=ty}),
                 [I.ICEXPORTEXN ({id=id,ty=ty,path=externPath},loc)]
                )
              else 
                (exnSet, V.emptyEnv, nil)
            else 
              (EU.enqueueError
                 (loc, E.ProvideExceptionType("CP-410", {longid = path}));
               raise Fail)
          | SOME (idstatus as I.IDEXEXN {path=_,ty, used, loc=_, version}) => 
            (EU.enqueueError
               (loc, E.ProvideExceptionType("CP-420", {longid = path}));
             raise Fail)
          | SOME (idstatus as I.IDEXEXNREP {path=_,ty, used, loc=_, version}) => 
            (EU.enqueueError
               (loc, E.ProvideExceptionType("CP-430", {longid = path}));
             raise Fail)
          | _ => 
            (EU.enqueueError
               (loc,
                E.ProvideUndefinedException("CP-440", {longid = path}));
             raise Fail)
        end
      | PI.PIEXCEPTIONREP {vid=name, origId=origPath, loc} =>
        (
        let
          val refIdstatus = 
              case V.findId (evalEnv, origPath) of
                NONE =>
                (
                 EU.enqueueError
                   (loc, E.ExceptionNameUndefined
                           ("CP-450",{longid = origPath}));
                 raise Fail)
              | SOME (idstatus as I.IDEXN {id,ty}) => idstatus
              | SOME (idstatus as I.IDEXNREP {id,ty}) => idstatus
              | SOME (idstatus as I.IDEXEXN {path,ty, used, loc, version}) => idstatus
              | SOME (idstatus as I.IDEXEXNREP {path,ty, used, loc, version}) => idstatus
              | _ => 
                (EU.enqueueError
                   (loc, E.ExceptionExpected
                           ("CP-460",{longid = origPath}));
                 raise Fail)
          val defIdstatus =
              case V.findId (env, [name]) of
                NONE =>
                (EU.enqueueError
                   (loc, E.ProvideUndefinedID
                           ("CP-470",{longid = origPath}));
                 raise Fail)
              | SOME (I.IDEXN {id,ty}) => 
                (EU.enqueueError
                   (loc, E.ProvideExceptionRep
                           ("CP-480",{longid = origPath}));
                 raise Fail)
              | SOME (idstatus as I.IDEXNREP _) => idstatus
              | SOME (idstatus as I.IDEXEXN _) => idstatus
              | SOME (idstatus as I.IDEXEXNREP _) => idstatus
              | _ => 
                (EU.enqueueError
                   (loc, E.ExceptionExpected
                           ("CP-490",{longid = origPath}));
                 raise Fail)
        in
          case defIdstatus of
            I.IDEXNREP {id=id1, ...} =>
            (case refIdstatus of
               I.IDEXN {id=id2,...} =>
               if ExnID.eq(id1, id2) then 
                 (exnSet,
                  V.rebindId(V.emptyEnv, name, defIdstatus),
                  nil)
               else
                 (EU.enqueueError
                    (loc, E.ProvideExceptionRepID("CP-500", {longid = path}));
                  raise Fail)
             | I.IDEXNREP {id=id2,...} => 
               if ExnID.eq(id1, id2) then 
                 (exnSet, V.rebindId(V.emptyEnv, name, defIdstatus),nil)
               else
                 (EU.enqueueError
                    (loc, E.ProvideExceptionRepID("CP-510", {longid = path}));
                  raise Fail)
             | _ =>
               (EU.enqueueError
                  (loc, E.ProvideExceptionRepID("CP-520", {longid = path}));
                raise Fail)
            )
          | I.IDEXEXN {path=path1, ...} =>
            (case refIdstatus of
               I.IDEXEXN {path=path2,...} =>
               if String.concat path1 = String.concat path2 then 
                 (exnSet, V.rebindId(V.emptyEnv, name, defIdstatus),nil)
               else
                 (EU.enqueueError
                    (loc, E.ProvideExceptionRepID("CP-530", {longid = path}));
                  raise Fail)
             | _ =>
               (EU.enqueueError
                  (loc, E.ProvideExceptionRepID("CP-540", {longid = path}));
                raise Fail)
            )
          | I.IDEXEXNREP {path=path1, ...} =>
            (case refIdstatus of
               I.IDEXEXNREP {path=path2,...} =>
               if String.concat path1 = String.concat path2 then 
                 (exnSet, V.rebindId(V.emptyEnv, name, defIdstatus),nil)
               else
                 (EU.enqueueError
                    (loc, E.ProvideExceptionRepID("CP-550", {longid = path}));
                  raise Fail)
             | _ =>
               (EU.enqueueError
                  (loc, E.ProvideExceptionRepID("CP-560", {longid = path}));
                raise Fail)
            )
          | _ => raise bug "impossible"
        end
        handle Fail => (exnSet, V.emptyEnv, nil)
        )
      | PI.PIDATATYPE {datbind, loc} =>
        (exnSet,
         checkDatbindList loc path evalEnv env datbind,
         nil)
      | PI.PISTRUCTURE {strid, strexp=PI.PISTRUCT {decs,loc=strLoc}, loc} =>
        (case V.findStr(env, [strid]) of
           SOME {env, strKind} => 
           let
             val (exnSet, returnEnv, icdecls) =
                 checkPidecList
                   exnSet strLoc (path@[strid]) evalTopEnv (env, decs)
             val strEntry = {env=returnEnv, strKind=strKind}
           in
             (exnSet, V.singletonStr(strid, strEntry), icdecls)
           end
         | NONE =>
           (EU.enqueueError
              (loc, E.ProvideUndefinedStr("CP-570", {longid=path@[strid]}));
            raise Fail)
        )
      | PI.PISTRUCTURE {strid, strexp=PI.PISTRUCTREP {strPath,loc=strLoc}, loc} =>
        (case V.findStr(env, [strid]) of
           SOME (strEntry1 as {env =_, strKind}) =>
           let
             val defId = case strKind of
                           V.STRENV id => id
                         | V.FUNAPP {id, ...} => id
                         | _ => 
                           (EU.enqueueError
                              (loc, E.ProvideStrRep("CP-580", {longid=path@[strid]}));
                            raise Fail)
           in
             (case V.findStr(evalEnv, strPath) of
                SOME (strEntry as {env=_, strKind}) =>
                let
                  val refId =
                      case strKind of
                        V.STRENV id => id
                      | V.FUNAPP {id,...} => id
                      | _ => 
                        (EU.enqueueError
                           (loc, E.ProvideStrRep("CP-590", {longid=path@[strid]}));
                         raise Fail)
                in
                  if StructureID.eq(defId, refId) then 
                    (exnSet, V.singletonStr(strid, strEntry), nil)
                  else 
                    (EU.enqueueError
                       (loc, E.ProvideStrRep("CP-600", {longid=path@[strid]}));
                     raise Fail)
                end
              | NONE => 
                (EU.enqueueError
                   (loc, E.ProvideUndefinedStr("CP-610", {longid=strPath}));
                 raise Fail
                )
             )
           end
         | NONE =>
           (EU.enqueueError
              (loc, E.ProvideUndefinedStr("CP-620", {longid=path@[strid]}));
            raise Fail)
        )
      | PI.PISTRUCTURE {strid, strexp=PI.PIFUNCTORAPP {functorName, argumentPath, loc=argLoc}, loc} =>
        (case V.findStr(env, [strid]) of
           SOME (strEntry as {env=strEnv, strKind}) => 
           (case strKind of
              V.FUNAPP {id, funId=funId1, argId=argId1} =>
              let
                val {FunE, Env, ...} = evalTopEnv
                val ({id=funId2, ...}:V.funEEntry) = 
                    case SEnv.find(FunE, functorName) of
                      SOME entry => entry
                    | NONE =>
                      (EU.enqueueError
                         (loc,E.ProvideUndefinedFunctorName ("CP-630",{longid = [functorName]}));
                       raise Fail)
                val {strKind,env=_} = 
                    case V.findStr(Env, argumentPath) of
                      SOME entry => entry
                    | NONE => 
                      (EU.enqueueError
                         (loc, E.ProvideUndefinedFunctorName ("CP-640",{longid = [functorName]}));
                       raise Fail)
                val argId2 = 
                    case strKind of
                      V.STRENV id => id
                    | V.FUNAPP {id,...} => id
                    | _ => 
                      (EU.enqueueError
                         (loc, E.ProvideUndefinedFunctorName ("CP-650",{longid = [functorName]}));
                       raise Fail)
                val _ = if FunctorID.eq(funId1, funId2) andalso
                           StructureID.eq(argId1, argId2)
                           then ()
                        else 
                          (
                           EU.enqueueError
                             (loc,
                              E.ProvideUndefinedFunctorName ("CP-660",{longid = [functorName]}));
                           raise Fail)
                val (exnSet, icdecls) = genTypedExportVarsEnv loc (path@[strid]) strEnv (exnSet,nil)
              in
                (exnSet, V.singletonStr(strid, strEntry), icdecls)
              end
            | _ => 
              (EU.enqueueError
                 (loc, E.ProvideUndefinedStr("CP-670", {longid=path@[strid]}));
               raise Fail)
           )
         | _ => 
           (EU.enqueueError
              (loc, E.ProvideUndefinedStr("CP-680", {longid=path@[strid]}));
            raise Fail)
        )
          
  and checkPidecList exnSet loc path (evalTopEnv as {Env=evalEnv, FunE, SigE}) (env, declList) =
      foldl
        (fn (decl, (exnSet, returnEnv, icdecls)) =>
            let
               val evalEnv = V.envWithEnv (evalEnv, returnEnv)
               val evalTopEnv = {Env=evalEnv, FunE=FunE, SigE=SigE}
               val (exnSet, newEnv, newIcdecls) =
                   checkPidec exnSet path evalTopEnv (env, decl)
               val returnEnv = V.unionEnv "CP-690" loc (returnEnv, newEnv)
            in
              (exnSet, returnEnv, icdecls@newIcdecls)
            end
        )
        (exnSet, V.emptyEnv, nil)
        declList

  fun checkPitopdec 
        exnSet
        (evalTopEnv as {Env=evalEnv, FunE=evalFunE, SigE=evalSigE})
        (topEnv as {Env, FunE, SigE}, pitopDec) =
      case pitopDec of
        PI.PIDEC pidec =>
        let
          val (exnSet, env, decls) =
              checkPidec exnSet nilPath evalTopEnv (Env, pidec)
        in
          (exnSet, V.topEnvWithEnv(V.emptyTopEnv, env), decls)
        end
      | PI.PIFUNDEC (piFunbind as
                    {funid=functorName,
                     param={strid=specArgStrName, sigexp=specArgSig},
                     strexp=specBodyStr,
                     loc})
        =>
        let
          val funEEntry
                as {id, version, used, argSig, argStrEntry, argStrName, dummyIdfunArgTy, polyArgTys, 
                    typidSet, exnIdSet, bodyEnv, bodyVarExp}
            =
            case SEnv.find(FunE, functorName) of
              NONE =>
              (EU.enqueueError
                 (loc,
                  E.ProvideUndefinedFunctorName("CP-700",{longid=[functorName]}));
               raise Fail
              )
            | SOME entry => entry
          val specArgSig = Sig.evalPlsig evalTopEnv specArgSig
          val _ = if EU.isAnyError () then raise Fail
                  else if FU.eqSize (specArgSig, argSig) 
                          andalso FU.eqEnv {specEnv=specArgSig, implEnv=argSig} then ()
                  else
                    (
                     EU.enqueueError
                       (loc,
                        E.ProvideFunparamMismatch("CP-710",
                                                  {longid=[functorName]}));
                     raise Fail
                    )
          val argEnv =
              V.ENV {varE=SEnv.empty,
                     tyE=SEnv.empty,
                     strE=V.STR (SEnv.singleton(specArgStrName, argStrEntry))
                    }
          val evalEnv = V.topEnvWithEnv (evalTopEnv, argEnv)
          val (_, specBodyInterfaceEnv, _) =
              EI.evalPistr [functorName] evalEnv (PathSet.empty, specBodyStr)
          val specBodyEnv = EI.internalizeEnv specBodyInterfaceEnv
          val _ = if EU.isAnyError () then raise Fail 
                  else if FU.eqEnv {specEnv=specBodyEnv, implEnv=bodyEnv} then 
                    ()
                  else 
                    (
                     EU.enqueueError
                       (loc,
                        E.ProvideFunctorMismatch("CP-720",
                                                  {longid=[functorName]}));
                     raise Fail
                    )
          val {allVars=allVars,
               typidSet=typidSet,
               exnIdSet = exnIdSet
              } =
              FU.makeBodyEnv specBodyEnv loc 
          fun varToTy (_, var) =
              case var of
                I.ICEXVAR ({path, ty},_) => ty
              | I.ICEXN ({path, id, ty},_) => ty
              | I.ICEXN_CONSTRUCTOR ({id, ty, path}, loc) => BV.exntagTy
              | _ =>  raise bug "VARTOTY\n"
          val bodyTy =
              case allVars of
                nil => BV.unitTy
              | _ => I.TYRECORD (Utils.listToFields (map varToTy allVars))
          val (extraTvars, firstArgTy) = 
              case dummyIdfunArgTy of
                NONE => (nil, NONE)
              | SOME (ty as I.TYRECORD fields) => 
                (map (fn (I.TYVAR tvar) => tvar
                       | _ => raise bug "non tvar in dummyIdfunArgTy")
                     (LabelEnv.listItems fields),
                 SOME (I.TYFUNM([ty],ty)))
              | _ => raise bug "non record ty in dummyIdfunArgTy"

          (* four possibilities in functorTy 
             1. TYPOLY(btvs, TYFUNM([first], TYFUNM(polyList, body)))
                ICFNM1([first], ICFNM1_POLY(polyPats, BODY))
             2. TYPOLY(btvs, TYFUNM([first], body))
                ICFNM1([first], BODY)
             3. TYFUNM(polyList, body)
                ICFNM1_POLY(polyPats, BODY)
             4. TYFUNM([unit], body)
                ICFNM1(UNIT, BODY)
            where body is either
              unit (TYCONSTRUCT ..) 
             or
              record (TYRECORD ..)
            BODY is ICLET(..., ICCONSTANT or ICRECORD)
           *)
          val functorTy1 =
              case polyArgTys of
                nil => bodyTy
              | _ => I.TYFUNM(polyArgTys, bodyTy)

          val functorTy2 =
              case firstArgTy of
                NONE => functorTy1
              | SOME ty => 
                I.TYPOLY
                  (map (fn x => (x, I.UNIV)) extraTvars,
                   I.TYFUNM([ty], functorTy1))

          val functorTy =
              case functorTy2 of
                I.TYPOLY _ => functorTy2
              | I.TYFUNM _ => functorTy2
              | _ => I.TYFUNM([BV.unitTy], functorTy2)

          val decls =
              case bodyVarExp of 
                I.ICVAR (varInfo, loc) => 
                [I.ICEXPORTFUNCTOR (varInfo, functorTy, loc)]
              | I.ICEXVAR ({path, ty}, loc) => nil
              | _ => raise bug "nonvar in bodyVarExp"
          val funEEntry =
              {id=id, 
               version = NONE,
               used = ref false,
               argSig=argSig, 
               argStrEntry=argStrEntry, 
               argStrName=argStrName, 
               dummyIdfunArgTy=dummyIdfunArgTy, 
               polyArgTys=polyArgTys, 
               typidSet=typidSet, 
               exnIdSet=exnIdSet, 
               bodyEnv=bodyEnv, 
               bodyVarExp=bodyVarExp
              }

          val funE =  SEnv.singleton(functorName, funEEntry)
          val returnTopEnv = V.topEnvWithFunE(V.emptyTopEnv, funE)
        in
          (exnSet, returnTopEnv, decls)
        end

in
  (* 
     evalTopEnv: the top-level environment constructred so far
     topEnv : the top-level environment of the current declarations 
              to be checked
   *)
  fun checkPitopdecList evalTopEnv (topEnv, pitopdecList) =
      let
        val (exnSet, returnTopEnv, icdecls) =
            foldl
              (fn (pitopdec, (exnSet, returnTopEnv, icdecls)) =>
                  let
                    val loc = PI.pitopdecLoc pitopdec
                    val evalTopEnv =
                        V.topEnvWithTopEnv (evalTopEnv, returnTopEnv)
                    val (exnSet, newTopEnv, newdecls) =
                        checkPitopdec exnSet evalTopEnv (topEnv,pitopdec)
                        handle e => raise e
                    val returnTopEnv =
                        V.unionTopEnv "CP-730" loc (returnTopEnv, newTopEnv)
                  in
                    (exnSet, returnTopEnv,icdecls@newdecls)
                  end
              )
              (ExnID.Set.empty, V.emptyTopEnv, nil)
              pitopdecList
      in
        icdecls
      end
      handle Fail => nil
           | exn => raise bug "Uncought exception in checkPitopdecList"
end
end
