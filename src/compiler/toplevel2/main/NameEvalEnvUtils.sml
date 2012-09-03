(**
 * utilities for name eval env.
 * @copyright (c) 2012, Tohoku University.
 *)

structure NameEvalEnvUtils : sig

  val mergeTypeEnv : NameEvalEnv.topEnv * TypeInferenceContext.varEnv
                     -> NameEvalEnv.topEnv
  val resetInternalId : NameEvalEnv.topEnv -> NameEvalEnv.topEnv
  val externOverloadInstances : NameEvalEnv.topEnv -> IDCalc.icdecl list

end =
struct

  structure I = IDCalc
  structure V = NameEvalEnv
  fun bug s = Control.Bug ("MergeTypeEnv: " ^ s)

  fun setTyIdstatus tyVarE idstatus =
      case idstatus of
      I.IDVAR varId => raise bug "IDVAR not found"
    | I.IDVAR_TYPED {id, ty} => raise bug "IDVAR not found"
    | I.IDEXVAR_TOBETYPED {path, id, loc, version, internalId} => 
      (case VarMap.find(tyVarE, {id=id, path=nil}) of
         NONE => raise bug "varId not found"
       | SOME (TypedCalc.VARID {ty,...})  => 
           I.IDEXVAR {path=path, 
                      version=version, 
                      used = ref false, 
                      internalId=internalId,
                      ty=I.INFERREDTY ty, 
                      loc=loc}
       | SOME (TypedCalc.RECFUNID ({ty,...},_))  => 
           I.IDEXVAR {path=path, 
                      version=version, 
                      used = ref false, 
                      internalId=internalId,
                      ty=I.INFERREDTY ty, 
                      loc=loc}
      )
    | I.IDEXVAR {path, ty, used, loc, version, internalId} => idstatus
    | I.IDBUILTINVAR  {primitive, ty} => idstatus
    | I.IDCON {id, ty} => idstatus
    | I.IDEXN {id, ty} => idstatus
    | I.IDEXNREP {id, ty} => idstatus
    | I.IDEXEXN {path, ty, used, loc, version} => idstatus
    | I.IDEXEXNREP {path, ty, used, loc, version} => idstatus
(*
    | I.IDOPRIM _ => raise bug "IDOPRIM in setTy"
*)
    | I.IDOPRIM _ => idstatus  (* FIXME *)
    | I.IDSPECVAR ty => raise bug "IDSPECVAR in setTy"
    | I.IDSPECEXN ty => raise bug "IDSPECEXN in setTy"
    | I.IDSPECCON => raise bug "IDSPECCON in setTy"

  fun setTyVarE tyVarE varE = 
      SEnv.map (setTyIdstatus tyVarE) varE

  fun setTyEnv tyVarE (NameEvalEnv.ENV {varE, tyE, strE}) =
      let
        val varE = setTyVarE tyVarE varE
        val strE = setTyStrE tyVarE strE
      in
        NameEvalEnv.ENV {varE=varE, tyE=tyE, strE=strE}
      end

  and setTyStrE tyVarE (NameEvalEnv.STR envMap) =
      NameEvalEnv.STR
        (SEnv.map
           (fn {env,strKind} => {env= setTyEnv tyVarE env, strKind=strKind})
           envMap)

  fun setTyFunE tyVarE funE =
      SEnv.map
      (fn {id, version, used, argSig, argStrEntry, argStrName, dummyIdfunArgTy,
           polyArgTys, typidSet, exnIdSet, bodyEnv, bodyVarExp} =>
          let
            val bodyVarExp =
                case bodyVarExp of
                  I.ICEXVAR_TOBETYPED ({path, id=id}, loc) =>
                  let
                    val ty =
                        case VarMap.find(tyVarE, {id=id, path=nil}) of
                          NONE => raise bug "varId not found"
                        | SOME (TypedCalc.VARID {ty,...}) => I.INFERREDTY ty
                        | SOME (TypedCalc.RECFUNID ({ty,...},_)) =>
                          I.INFERREDTY ty
                  in
                    I.ICEXVAR ({path=path, ty= ty}, loc)
                  end
                | _ => bodyVarExp
          in
            {id=id,
             version = version,
             used = used,
             argSig = argSig,
             argStrEntry = argStrEntry,
             argStrName = argStrName,
             dummyIdfunArgTy = dummyIdfunArgTy,
             polyArgTys = polyArgTys,
             typidSet = typidSet,
             exnIdSet = exnIdSet,
             bodyEnv = bodyEnv,
             bodyVarExp = bodyVarExp
            }
          end
      )
      funE

  fun setTy (env as {FunE, SigE, Env}) tyVarE =
      let
        val FunE = setTyFunE tyVarE  FunE
        val Env = setTyEnv tyVarE  Env
      in
        {FunE=FunE, SigE=SigE, Env=Env}
      end

  fun mergeTypeEnv (topEnv, tyEnv) =
      setTy topEnv tyEnv

  fun resetInternalIdIdstatus idstatus =
      case idstatus of
      I.IDEXVAR {path, ty, used, loc, version, internalId} =>
      I.IDEXVAR {path=path, ty=ty, used=used, loc=loc, version=version, internalId=NONE}
    | idstatus => idstatus

  fun resetInternalIdEnv (V.ENV{varE, strE, tyE}) =
      let
        val varE = SEnv.map resetInternalIdIdstatus varE
        val strE = resetInternalIdStrE strE
      in
        V.ENV{varE=varE, strE=strE, tyE=tyE}
      end

  and resetInternalIdStrE (V.STR strEmap) =
      let
        val strEmap = 
            SEnv.map 
            (fn {env, strKind} =>
                {env=resetInternalIdEnv env, strKind=strKind}
            )
            strEmap
      in
        V.STR strEmap
      end

  fun resetInternalId ({Env, FunE, SigE}:V.topEnv) =
      let
        val Env = resetInternalIdEnv Env
      in
        {Env=Env, FunE=FunE, SigE=SigE}
      end

  fun scanOverloadInstance inst =
      case inst of
        I.INST_OVERLOAD overloadCase => scanOverloadCase overloadCase
      | I.INST_EXVAR ({path, used, ty}, loc) =>
        [I.ICEXTERNVAR ({path=path, ty=ty}, loc)]
      | I.INST_PRIM _ => nil

  and scanOverloadCase ({tvar, expTy, matches, loc}:I.overloadCase) =
      foldr (fn ({instTy, instance}, z) => scanOverloadInstance instance @ z)
            nil
            matches

  fun scanOverloadDef icdecl =
      case icdecl of
        I.ICOVERLOADDEF {boundtvars, id, path, overloadCase, loc} =>
        scanOverloadCase overloadCase
      | _ => raise Control.Bug "scanOverloadDef"

  fun scanIdStatus idstatus =
      case idstatus of
        I.IDVAR _ => nil
      | I.IDVAR_TYPED _ => nil
      | I.IDEXVAR _ => nil
      | I.IDEXVAR_TOBETYPED _ => nil
      | I.IDBUILTINVAR _ => nil
      | I.IDCON _ => nil
      | I.IDEXN _ => nil
      | I.IDEXNREP _ => nil
      | I.IDEXEXN _ => nil
      | I.IDEXEXNREP _ => nil
      | I.IDOPRIM {id, overloadDef, used, loc} => scanOverloadDef overloadDef
      | I.IDSPECVAR _ => nil
      | I.IDSPECEXN _ => nil
      | I.IDSPECCON => nil

  fun scanVarEnv varEnv =
      SEnv.foldr (fn (idstatus, z) => scanIdStatus idstatus @ z)
                 nil
                 varEnv

  fun scanEnv (V.ENV {varE, tyE, strE}) =
      scanVarEnv varE @ scanStrEnv strE

  and scanStrEnv (V.STR strEnv) =
      SEnv.foldr (fn ({env, strKind}, z) => scanEnv env @ z)
                 nil
                 strEnv

  fun externOverloadInstances ({Env, FunE, SigE}:V.topEnv) =
      scanEnv Env

end
