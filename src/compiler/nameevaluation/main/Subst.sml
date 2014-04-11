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
  fun bug s = Bug.Bug ("Subst: " ^ s)
in
  type tvarSubst = I.ty TvarMap.map
  type tfvSubst = (I.tfunkind ref) TfvMap.map
  type conIdSubst = I.idstatus ConID.Map.map
  type exnIdSubst = ExnID.id ExnID.Map.map
  type subst = {tvarS:tvarSubst,
                exnIdS:exnIdSubst,
                conIdS:conIdSubst}
  val emptyTvarSubst : tvarSubst = TvarMap.empty
  val emptyTfvSubst : tfvSubst = TfvMap.empty
  val emptyConIdSubst : conIdSubst = ConID.Map.empty
  val emptyExnIdSubst : exnIdSubst = ExnID.Map.empty
  val emptySubst : subst = {tvarS=emptyTvarSubst,
                    exnIdS=emptyExnIdSubst,
                    conIdS=emptyConIdSubst}
  local
    val visitedSet = ref (TfvSet.empty)
    fun resetSet () = visitedSet := TfvSet.empty
    fun visit tfv = visitedSet := TfvSet.add(!visitedSet, tfv)
    fun isVisited tfv = TfvSet.member(!visitedSet, tfv)
    (* here we only substitute conid; this is to refresh conid *)
    (* subst is also used for instantiation where we need to substitute
       conidstatus including ty *)
    fun substConId (subst:subst) id =
        case ConID.Map.find(#conIdS subst, id) of
          SOME (I.IDCON {id,...}) => id
        | SOME _ => raise bug "substConId"
        | NONE => id
    fun substTfunkind subst tfunkind =
        case tfunkind of
          I.TFV_SPEC {longsymbol, id, iseq, formals} => tfunkind
        | I.TFV_DTY {longsymbol, id,iseq,formals,conSpec,liftedTys} =>
          I.TFV_DTY {id=id,
                     longsymbol=longsymbol,
                     iseq=iseq,
                     formals=formals,
                     conSpec=substConSpec subst conSpec,
                     liftedTys=liftedTys
                    }
        | I.TFUN_DTY {id,iseq,formals,runtimeTy,longsymbol,
                      conSpec,conIDSet, liftedTys,dtyKind} =>
          I.TFUN_DTY {id=id,
                      iseq=iseq,
                      (* 
		      runtimeTy=runtimeTy,
                      2012-7-18 ohori: bug 210_functor.sml
                       *)
		      runtimeTy=substRuntimeTy subst runtimeTy,
                      formals=formals,
                      conSpec=substConSpec subst conSpec,
                      conIDSet = ConID.Set.map (substConId subst) conIDSet,
                      longsymbol=longsymbol,
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

    and substRuntimeTy (subst:subst as {tvarS,...}) runtimeTy =
        case runtimeTy of
          I.BUILTINty _ => runtimeTy
        | I.LIFTEDty tvar => 
          (case TvarMap.find(tvarS, tvar) of
             SOME (I.TYVAR (tvar as {lifted,...})) => 
             I.LIFTEDty tvar
           | SOME ty =>
             (case I.runtimeTyOfIty ty of
                SOME runtimeTy => runtimeTy
              | NONE => raise bug "runtimeTy not found in substRuntimeTy"
             )
           | NONE => runtimeTy
          )
    and substConSpec subst conSpec =
        SymbolEnv.map
        (fn tyOpt => Option.map (substTy subst) tyOpt)
        conSpec
    and substTfun (subst:subst as {tvarS,...}) tfun = 
        case I.derefTfun tfun of
        I.TFUN_DEF {longsymbol, iseq, formals=nil, realizerTy=I.TYVAR tvar} =>
        (case TvarMap.find(tvarS, tvar) of
           SOME ty => I.TFUN_DEF{longsymbol=longsymbol, iseq=iseq, formals=nil, realizerTy=ty}
         | NONE => I.TFUN_DEF {longsymbol=longsymbol, iseq=iseq, formals=nil, realizerTy=I.TYVAR tvar}
        )
      | I.TFUN_DEF {longsymbol, iseq, formals, realizerTy} =>
        I.TFUN_DEF {longsymbol=longsymbol,
                    iseq=iseq,
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
        | I.TYCONSTRUCT {tfun, args} =>
          I.TYCONSTRUCT
            {tfun=substTfun subst tfun,
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

    and substKindedTvar subst  (tvar, tvarKind) =
        (tvar, substKind subst tvarKind)
    and substKind subst tvarKind
      = case tvarKind of
          I.UNIV => I.UNIV
        | I.REC fields => I.REC (LabelEnv.map (substTy subst) fields)
    fun substExnId (subst:subst)  id =
        case ExnID.Map.find(#exnIdS subst, id) of
          SOME newId => newId
        | NONE => id
    fun substExInfo subst {longsymbol, ty, version} =
        {longsymbol=longsymbol, ty=substTy subst ty, version=version}
    fun substIdstatus subst idstatus = 
        case idstatus of
          I.IDVAR _ => idstatus
        | I.IDVAR_TYPED _ => idstatus
        | I.IDEXVAR {exInfo, used, internalId} => 
          I.IDEXVAR {exInfo=substExInfo subst exInfo, used = ref (!used), 
                     internalId=internalId}
        | I.IDEXVAR_TOBETYPED {longsymbol, id, version} => idstatus
        | I.IDBUILTINVAR {primitive, ty} =>
          I.IDBUILTINVAR {primitive=primitive, ty=substTy subst ty}
        | I.IDCON {id, longsymbol, ty} => 
          I.IDCON {id=substConId subst id, longsymbol=longsymbol, ty=substTy subst ty}
        | I.IDEXN {id, longsymbol, ty} =>
          let
            val exnInfo = {id=substExnId subst id, longsymbol=longsymbol, ty=substTy subst ty}
            val _ = IV.exnConAdd (IV.EXN exnInfo)
          in
            I.IDEXN exnInfo
          end
        | I.IDEXNREP {id, longsymbol, ty} =>
          I.IDEXNREP {id=substExnId subst id, longsymbol=longsymbol,ty=substTy subst ty}
        | I.IDEXEXN ({longsymbol, ty, version},used) => 
          I.IDEXEXN ({longsymbol=longsymbol, ty=substTy subst ty, version=version}, ref (!used))
        | I.IDEXEXNREP ({longsymbol, ty, version},used) => 
          I.IDEXEXNREP ({longsymbol=longsymbol, ty=substTy subst ty, version=version}, ref (!used))
        | I.IDOPRIM {id, overloadDef, used, longsymbol} =>
          I.IDOPRIM {id=id, overloadDef=overloadDef, used = ref (!used),
                     longsymbol=longsymbol}
        | I.IDSPECVAR {ty, symbol} => I.IDSPECVAR {ty=substTy subst ty, symbol=symbol}
        | I.IDSPECEXN {ty, symbol} => I.IDSPECEXN {ty=substTy subst ty, symbol=symbol}
        | I.IDSPECCON {symbol} => I.IDSPECCON {symbol=symbol} 
    fun substVarE subst varE = SymbolEnv.map (substIdstatus subst) varE
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
                         conSpec= SymbolEnv.map (Option.map (substTy subst)) conSpec
                        }
        end
    fun substTyE subst tyE = SymbolEnv.map (substTstr subst) tyE
    fun substEnv subst (IV.ENV {varE, tyE, strE}) =
        IV.ENV
          {varE = substVarE subst varE,
           tyE = substTyE subst tyE,
           strE = substStrE subst strE
          }
    and substStrE subst (IV.STR specEnvMap) =
        IV.STR (SymbolEnv.map
                  (fn {env, strKind} => 
                      {env=substEnv subst env, strKind=strKind}) specEnvMap)
  
  in
    val substEnv = fn subst => fn env => (resetSet(); substEnv subst env)
    val substTy = fn subst => fn ty => (resetSet(); substTy subst ty)
    val substVarE = fn subst => fn varE => (resetSet(); substVarE subst varE)
  end

  fun substTfvTfun tfvSubst tfun = 
      case I.derefTfun tfun of
        I.TFUN_DEF {longsymbol, iseq, formals, realizerTy} =>
        I.TFUN_DEF {iseq=iseq,
                    longsymbol=longsymbol,
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
      | I.TYCONSTRUCT {tfun, args} =>
        I.TYCONSTRUCT
          {tfun=substTfvTfun tfvSubst tfun,
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

  and substTfvKindedTvar tfvSubst  (tvar, tvarKind) =
      (tvar, substTfvKind tfvSubst tvarKind)

  and substTfvKind tfvSubst tvarKind
    = case tvarKind of
        I.UNIV => I.UNIV
      | I.REC fields => I.REC (LabelEnv.map (substTfvTy tfvSubst) fields)

  fun substTfvIdstatus tfvSubst idstatus = 
      case idstatus of
        I.IDVAR varId => idstatus
      | I.IDVAR_TYPED {id, longsymbol, ty} => 
        I.IDVAR_TYPED {id=id, longsymbol=longsymbol, ty=substTfvTy tfvSubst ty}
      | I.IDEXVAR {exInfo={longsymbol, version, ty}, used, internalId} => 
        I.IDEXVAR {exInfo = {longsymbol=longsymbol, version=version, ty = substTfvTy tfvSubst ty},
                   used=used, internalId=internalId}
      | I.IDEXVAR_TOBETYPED _ => idstatus
      | I.IDBUILTINVAR {primitive, ty} =>
        I.IDBUILTINVAR {primitive=primitive, ty=substTfvTy tfvSubst ty}
      | I.IDCON {id, longsymbol, ty} => I.IDCON {id=id, longsymbol=longsymbol, ty=substTfvTy tfvSubst ty}
      | I.IDEXN {id, longsymbol, ty} => I.IDEXN {id=id, longsymbol=longsymbol, ty=substTfvTy tfvSubst ty}
      | I.IDEXNREP {id, longsymbol, ty} => I.IDEXNREP {id=id, longsymbol=longsymbol, ty=substTfvTy tfvSubst ty}
      | I.IDEXEXN ({longsymbol, ty, version}, used) => 
        I.IDEXEXN ({longsymbol=longsymbol, ty=substTfvTy tfvSubst ty, version=version}, used)
      | I.IDEXEXNREP ({longsymbol, ty, version}, used) => 
        I.IDEXEXNREP ({longsymbol=longsymbol, ty=substTfvTy tfvSubst ty, version=version}, used)
      | I.IDOPRIM _ => idstatus
      | I.IDSPECVAR {ty, symbol} => I.IDSPECVAR {ty=substTfvTy tfvSubst ty, symbol=symbol}
      | I.IDSPECEXN {ty, symbol} => I.IDSPECEXN {ty=substTfvTy tfvSubst ty, symbol=symbol}
      | I.IDSPECCON {symbol} => I.IDSPECCON {symbol=symbol}

  fun substTfvVarE tfvSubst varE = SymbolEnv.map (substTfvIdstatus tfvSubst) varE

  fun substTfvTstr tfvSubst tstr = 
      case tstr of 
        IV.TSTR tfun => IV.TSTR (substTfvTfun tfvSubst tfun)
      | IV.TSTR_DTY {tfun, varE, formals, conSpec} =>
        IV.TSTR_DTY {tfun=substTfvTfun tfvSubst tfun,
                    varE=substTfvVarE tfvSubst varE,
                    formals=formals,
                    conSpec=SymbolEnv.map (Option.map (substTfvTy tfvSubst)) conSpec
                   }

  fun substTfvTyE tfvSubst tyE = SymbolEnv.map (substTfvTstr tfvSubst) tyE

  fun substTfvEnv tfvSubst (IV.ENV {varE, tyE, strE}) =
      IV.ENV
        {varE = substTfvVarE tfvSubst varE,
         tyE = substTfvTyE tfvSubst tyE,
         strE = substTfvStrE tfvSubst strE
        }
  and substTfvStrE tfvSubst (IV.STR specEnvMap) =
      IV.STR
        (SymbolEnv.map
           (fn {env, strKind} => 
               {env=substTfvEnv tfvSubst env, strKind=strKind}) specEnvMap)


end
end
