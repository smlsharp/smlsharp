(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
(* the initial error code of this file : S-001 *)
structure Subst :
sig
  type tvarSubst
  type tfvSubst
  type conIdSubst
  type exnIdSubst
  type subst
  val emptyConIdSubst : conIdSubst
  val emptyExnIdSubst : exnIdSubst
  val emptySubst : subst
  val emptyTvarSubst : tvarSubst
  val emptyTfvSubst : tfvSubst
  val substEnv : subst -> NameEvalEnv.env -> NameEvalEnv.env
  val substTy : subst -> IDCalc.ty -> IDCalc.ty
  val substTfvTy : tfvSubst -> IDCalc.ty -> IDCalc.ty
  val substTfvTfun : tfvSubst -> IDCalc.tfun -> IDCalc.tfun
  val substTfvEnv : tfvSubst -> NameEvalEnv.env -> NameEvalEnv.env
end
=
struct
local
  structure I = IDCalc
  structure IV = NameEvalEnv
  fun bug s = Control.Bug ("Subst: " ^ s)
in
  type tvarSubst = I.ty TvarMap.map
  type tfvSubst = (I.tfunkind ref) TfvMap.map
  type conIdSubst = I.idstatus ConID.Map.map
  type exnIdSubst = ExnID.id ExnID.Map.map
  type subst = {tvarS:tvarSubst,
                tfvS:tfvSubst,
                exnIdS:exnIdSubst,
                conIdS:conIdSubst}
  val emptyTvarSubst = TvarMap.empty
  val emptyTfvSubst = TfvMap.empty
  val emptyConIdSubst = ConID.Map.empty
  val emptyExnIdSubst = ExnID.Map.empty
  val emptySubst = {tvarS=emptyTvarSubst,
                    tfvS=emptyTfvSubst,
                    exnIdS=emptyExnIdSubst,
                    conIdS=emptyConIdSubst}
  local
    val visitedSet = ref (TfvSet.empty)
    fun resetSet () = visitedSet := TfvSet.empty
    fun visit tfv = visitedSet := TfvSet.add(!visitedSet, tfv)
    fun isVisited tfv = TfvSet.member(!visitedSet, tfv)
    fun substTfunkind subst tfunkind =
        case tfunkind of
          I.TFV_SPEC {id, iseq, formals} => tfunkind
        | I.TFV_DTY {id,iseq,formals,conSpec,liftedTys} =>
          I.TFV_DTY {id=id,
                     iseq=iseq,
                     formals=formals,
                     conSpec=substConSpec subst conSpec,
                     liftedTys=liftedTys
                    }
        | I.TFUN_DTY {id,iseq,formals,runtimeTy,originalPath,
                      conSpec,liftedTys,dtyKind} =>
          I.TFUN_DTY {id=id,
                      iseq=iseq,
		      runtimeTy=runtimeTy,
                      formals=formals,
                      conSpec=substConSpec subst conSpec,
                      originalPath=originalPath,
                      liftedTys=liftedTys,
                      dtyKind=
                      case dtyKind of
                        I.DTY => dtyKind
                      | I.DTY_INTERFACE => dtyKind
                      | I.FUNPARAM => dtyKind
                      | I.BUILTIN _ => dtyKind
                      | I.OPAQUE {tfun,revealKey} =>
                        I.OPAQUE {tfun=substTfun subst tfun,
                                  revealKey=revealKey}
                     }
        | I.REALIZED {id, tfun} => raise bug "REALIZED"
        | I.INSTANTIATED {tfunkind, tfun} => raise bug "REALIZED"
        | I.FUN_DTY _ => raise bug "FUN_DTY"

    and substConSpec subst conSpec =
        SEnv.map
        (fn tyOpt => Option.map (substTy subst) tyOpt)
        conSpec
    and substTfun (subst:subst as {tvarS,...}) tfun = 
        case I.derefTfun tfun of
        I.TFUN_DEF {iseq, formals=nil, realizerTy=I.TYVAR tvar} =>
        (case TvarMap.find(tvarS, tvar) of
           SOME ty => I.TFUN_DEF{iseq=iseq, formals=nil, realizerTy=ty}
         | NONE => I.TFUN_DEF {iseq=iseq, formals=nil, realizerTy=I.TYVAR tvar}
        )
      | I.TFUN_DEF {iseq, formals, realizerTy} =>
        I.TFUN_DEF {iseq=iseq,
                    formals=formals,
                    realizerTy=substTy subst realizerTy}
      | I.TFUN_VAR (tfv as ref (tfunkind as (I.TFV_SPEC _))) =>
        if isVisited tfv then I.TFUN_VAR tfv
        else
          let
            val _ = visit tfv
            val tfunkind = substTfunkind subst tfunkind
            val _ = tfv := tfunkind
          in
            I.TFUN_VAR tfv
          end
      | I.TFUN_VAR (tfv as ref (tfunkind as (I.TFV_DTY _))) => 
        if isVisited tfv then I.TFUN_VAR tfv
        else
          let
            val _ = visit tfv;
            val tfunkind = substTfunkind subst tfunkind
            val _ = tfv := tfunkind
          in
            I.TFUN_VAR tfv
          end
      | I.TFUN_VAR (tfv as ref (tfunkind as (I.TFUN_DTY _))) => 
        if isVisited tfv then I.TFUN_VAR tfv
        else
          let
            val _ = visit tfv;
            val tfunkind = substTfunkind subst tfunkind
            val _ = tfv := tfunkind
          in
            I.TFUN_VAR tfv
          end
      | I.TFUN_VAR (tfv as ref (I.INSTANTIATED{tfunkind, tfun})) => 
        let
          val tfunkind = substTfunkind subst tfunkind
          val tfun = substTfun subst tfun
          val _ = tfv := I.INSTANTIATED{tfunkind=tfunkind, tfun=tfun}
        in
          I.TFUN_VAR tfv
        end
      | I.TFUN_VAR _ => tfun
    and substTy (subst:subst as {tvarS,...}) (ty:I.ty) : I.ty =
        case ty of
          I.TYWILD => ty
        | I.TYVAR (tvar) => 
          (case TvarMap.find(tvarS, tvar) of
             SOME ty => ty
           | NONE => ty
          )
        | I.TYRECORD fields =>
          I.TYRECORD (LabelEnv.map (substTy subst) fields)
        | I.TYCONSTRUCT {typ, args} =>
          I.TYCONSTRUCT
            {typ=substTypInfo subst typ,
             args=map (substTy subst) args
            }
        | I.TYFUNM (tyList, ty2) =>
          I.TYFUNM (map (substTy subst) tyList, substTy subst ty2)
        | I.TYPOLY (kindedTvarList, ty) =>
          I.TYPOLY (map (substKindedTvar subst) kindedTvarList, 
                    substTy subst ty
                   )
        | I.TYERROR => I.TYERROR
        | I.INFERREDTY _ => ty

    and substTypInfo (subst:subst) {path, tfun} =
        {path=path, tfun=substTfun subst tfun}
    and substKindedTvar subst  (tvar, tvarKind) =
        (tvar, substKind subst tvarKind)
    and substKind subst tvarKind
      = case tvarKind of
          I.UNIV => I.UNIV
        | I.REC fields => I.REC (LabelEnv.map (substTy subst) fields)
    (* here we only substitute conid; this is to refresh conid *)
    (* subst is also used for instantiation where we need to substitute
       conidstatus including ty *)
    fun substConId (subst:subst) id =
        case ConID.Map.find(#conIdS subst, id) of
          SOME (I.IDCON{id,ty}) => id
        | SOME _ => raise bug "substConId"
        | NONE => id
    fun substExnId (subst:subst)  id =
        case ExnID.Map.find(#exnIdS subst, id) of
          SOME newId => newId
        | NONE => id
    fun substIdstatus subst idstatus = 
        case idstatus of
          I.IDVAR varId => idstatus
        | I.IDVAR_TYPED _ => idstatus
        | I.IDEXVAR {path, ty, used, loc, version, internalId} => 
          I.IDEXVAR {path=path, ty=substTy subst ty, used=used, loc=loc, 
                     version=version, internalId=internalId}
        | I.IDEXVAR_TOBETYPED {path, id, loc, version, internalId} => idstatus
        | I.IDBUILTINVAR {primitive, ty} =>
          I.IDBUILTINVAR {primitive=primitive, ty=substTy subst ty}
        | I.IDCON {id, ty} => 
          I.IDCON {id=substConId subst id, ty=substTy subst ty}
        | I.IDEXN {id, ty} =>
          I.IDEXN {id=substExnId subst id, ty=substTy subst ty}
        | I.IDEXNREP {id, ty} =>
          I.IDEXNREP {id=substExnId subst id, ty=substTy subst ty}
        | I.IDEXEXN {path, ty, used, loc, version} => 
          I.IDEXEXN {path=path, ty=substTy subst ty, used=used, loc=loc, version=version}
        | I.IDEXEXNREP {path, ty, used, loc, version} => 
          I.IDEXEXNREP {path=path, ty=substTy subst ty, used=used, loc=loc,version=version}
        | I.IDOPRIM _ => idstatus
        | I.IDSPECVAR ty => I.IDSPECVAR (substTy subst ty)
        | I.IDSPECEXN ty => I.IDSPECEXN (substTy subst ty)
        | I.IDSPECCON => idstatus
    fun substVarE subst varE = SEnv.map (substIdstatus subst) varE
    fun substTstr subst tstr =
        let
          val {tvarS,...} = subst
        in
          case tstr of 
            IV.TSTR tfun => IV.TSTR (substTfun subst tfun)
          | IV.TSTR_DTY {tfun, varE, formals, conSpec} =>
            IV.TSTR_DTY {tfun=substTfun subst tfun,
                        varE=substVarE subst varE,
                        formals=formals,
                        conSpec= SEnv.map (Option.map (substTy subst)) conSpec
                       }
(* This is now mover to substTfun (TFUN_DEF)
          | IV.TSTR_TOTVAR {id, iseq, tvar} => 
            case TvarMap.find(tvarS, tvar) of
              SOME ty =>
              let
                val tfun = I.TFUN_DEF{iseq=iseq, formals=nil, realizerTy=ty}
              in
                IV.TSTR tfun
              end
            | NONE => tstr
*)
        end
    fun substTyE subst tyE = SEnv.map (substTstr subst) tyE
    fun substEnv subst (IV.ENV {varE, tyE, strE}) =
        IV.ENV
          {varE = substVarE subst varE,
           tyE = substTyE subst tyE,
           strE = substStrE subst strE
          }
    and substStrE subst (IV.STR specEnvMap) =
        IV.STR (SEnv.map (fn {env, strKind} => {env=substEnv subst env, strKind=strKind}) specEnvMap)
  
  in
    val substEnv = fn subst => fn env => (resetSet(); substEnv subst env)
    val substTy = fn subst => fn ty => (resetSet(); substTy subst ty)
    val substVarE = fn subst => fn varE => (resetSet(); substVarE subst varE)
  end

  fun substTfvTfun tfvSubst tfun = 
      case I.derefTfun tfun of
        I.TFUN_DEF {iseq, formals, realizerTy} =>
        I.TFUN_DEF {iseq=iseq,
                    formals=formals,
                    realizerTy=substTfvTy tfvSubst realizerTy}
      | I.TFUN_VAR (tfv as ref (I.TFV_SPEC _)) =>
        (case TfvMap.find(tfvSubst, tfv) of
           NONE => tfun
         | SOME tfv => I.TFUN_VAR tfv
        )
      | I.TFUN_VAR (tfv as ref (I.TFV_DTY _)) => 
        (case TfvMap.find(tfvSubst, tfv) of
           NONE => tfun
         | SOME tfv => I.TFUN_VAR tfv
        )
      | I.TFUN_VAR (tfv as ref (I.TFUN_DTY _)) => 
        (case TfvMap.find(tfvSubst, tfv) of
           NONE => tfun
         | SOME tfv => I.TFUN_VAR tfv
        )
      | I.TFUN_VAR (tfv as ref (I.INSTANTIATED _)) => 
        (case TfvMap.find(tfvSubst, tfv) of
           NONE => tfun
         | SOME tfv => I.TFUN_VAR tfv
        )
      | I.TFUN_VAR _ => tfun

  and substTfvTy (tfvSubst:tfvSubst) (ty:I.ty) : I.ty =
      case ty of
        I.TYWILD => ty
      | I.TYVAR tvar => ty
      | I.TYRECORD fields =>
        I.TYRECORD (LabelEnv.map (substTfvTy tfvSubst) fields)
      | I.TYCONSTRUCT {typ, args} =>
        I.TYCONSTRUCT
          {typ=substTfvTypInfo tfvSubst typ,
           args=map (substTfvTy tfvSubst) args
          }
      | I.TYFUNM (tyList, ty2) =>
        I.TYFUNM (map (substTfvTy tfvSubst) tyList, substTfvTy tfvSubst ty2)
      | I.TYPOLY (kindedTvarList, ty) =>
        I.TYPOLY (map (substTfvKindedTvar tfvSubst) kindedTvarList, 
                  substTfvTy tfvSubst ty
                 )
      | I.TYERROR => I.TYERROR
      | I.INFERREDTY _ => ty

  and substTfvTypInfo (tfvSubst:tfvSubst) {path, tfun} =
      {path=path, tfun=substTfvTfun tfvSubst tfun}

  and substTfvKindedTvar tfvSubst  (tvar, tvarKind) =
      (tvar, substTfvKind tfvSubst tvarKind)

  and substTfvKind tfvSubst tvarKind
    = case tvarKind of
        I.UNIV => I.UNIV
      | I.REC fields => I.REC (LabelEnv.map (substTfvTy tfvSubst) fields)

  fun substTfvIdstatus tfvSubst idstatus = 
      case idstatus of
        I.IDVAR varId => idstatus
      | I.IDVAR_TYPED _ => idstatus
      | I.IDEXVAR {path, ty, used, loc, version, internalId} => 
        I.IDEXVAR {path=path, ty=substTfvTy tfvSubst ty, used=used, loc=loc, 
                   version=version, internalId=internalId}
      | I.IDEXVAR_TOBETYPED _ => idstatus
      | I.IDBUILTINVAR {primitive, ty} =>
        I.IDBUILTINVAR {primitive=primitive, ty=substTfvTy tfvSubst ty}
      | I.IDCON {id, ty} => I.IDCON {id=id, ty=substTfvTy tfvSubst ty}
      | I.IDEXN {id, ty} => I.IDEXN {id=id, ty=substTfvTy tfvSubst ty}
      | I.IDEXNREP {id, ty} => I.IDEXNREP {id=id, ty=substTfvTy tfvSubst ty}
      | I.IDEXEXN {path, ty, used, loc,version} => 
        I.IDEXEXN {path=path, ty=substTfvTy tfvSubst ty, used=used, loc=loc, version=version}
      | I.IDEXEXNREP {path, ty, used, loc, version} => 
        I.IDEXEXNREP {path=path, ty=substTfvTy tfvSubst ty, used=used, loc=loc, version=version}
      | I.IDOPRIM _ => idstatus
      | I.IDSPECVAR ty => I.IDSPECVAR (substTfvTy tfvSubst ty)
      | I.IDSPECEXN ty => I.IDSPECEXN(substTfvTy tfvSubst ty)
      | I.IDSPECCON => idstatus

  fun substTfvVarE tfvSubst varE = SEnv.map (substTfvIdstatus tfvSubst) varE

  fun substTfvTstr tfvSubst tstr = 
      case tstr of 
        IV.TSTR tfun => IV.TSTR (substTfvTfun tfvSubst tfun)
      | IV.TSTR_DTY {tfun, varE, formals, conSpec} =>
        IV.TSTR_DTY {tfun=substTfvTfun tfvSubst tfun,
                    varE=substTfvVarE tfvSubst varE,
                    formals=formals,
                    conSpec=SEnv.map (Option.map (substTfvTy tfvSubst)) conSpec
                   }

  fun substTfvTyE tfvSubst tyE = SEnv.map (substTfvTstr tfvSubst) tyE

  fun substTfvEnv tfvSubst (IV.ENV {varE, tyE, strE}) =
      IV.ENV
        {varE = substTfvVarE tfvSubst varE,
         tyE = substTfvTyE tfvSubst tyE,
         strE = substTfvStrE tfvSubst strE
        }
  and substTfvStrE tfvSubst (IV.STR specEnvMap) =
      IV.STR (SEnv.map (fn {env, strKind} => {env=substTfvEnv tfvSubst env, strKind=strKind}) specEnvMap)


end
end
