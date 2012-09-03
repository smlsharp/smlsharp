(* the initial error code of this file : S-001 *)
structure Subst =
struct
local
  structure I = IDCalc
  structure T = IDTypes
  structure IV = NameEvalEnv
  fun bug s = Control.Bug ("Subst: " ^ s)
in
  type tvarSubst = T.ty TvarMap.map
  type tfvSubst = (T.tfunkind ref) TfvMap.map
  type conIdSubst = T.idstatus ConID.Map.map
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
          T.TFV_SPEC {id, iseq, formals} => tfunkind
        | T.TFV_DTY {id,iseq,formals,conSpec,liftedTys} =>
          T.TFV_DTY {id=id,
                     iseq=iseq,
                     formals=formals,
                     conSpec=substConSpec subst conSpec,
                     liftedTys=liftedTys
                    }
        | T.TFUN_DTY {id,iseq,formals,conSpec,liftedTys,dtyKind} =>
          T.TFUN_DTY {id=id,
                      iseq=iseq,
                      formals=formals,
                      conSpec=substConSpec subst conSpec,
                      liftedTys=liftedTys,
                      dtyKind=
                      case dtyKind of
                        T.DTY => dtyKind
                      | T.FUNPARAM => dtyKind
                      | T.BUILTIN _ => dtyKind
                      | T.OPAQUE {tfun,revealKey} =>
                        T.OPAQUE {tfun=substTfun subst tfun,
                                  revealKey=revealKey}
                     }
        | T.REALIZED {id, tfun} => raise bug "REALIZED"
        | T.INSTANTIATED {tfunkind, tfun} => raise bug "REALIZED"
        | T.FUN_TOTVAR _ => raise bug "FUN_TOTVAR"
        | T.FUN_DTY _ => raise bug "FUN_DTY"

    and substConSpec subst conSpec =
        SEnv.map
        (fn tyOpt => Option.map (substTy subst) tyOpt)
        conSpec
    and substTfun subst tfun = 
        case T.derefTfun tfun of
        T.TFUN_DEF {iseq, formals, realizerTy} =>
        T.TFUN_DEF {iseq=iseq,
                    formals=formals,
                    realizerTy=substTy subst realizerTy}
      | T.TFUN_VAR (tfv as ref (tfunkind as (T.TFV_SPEC _))) =>
        if isVisited tfv then T.TFUN_VAR tfv
        else
          let
            val _ = visit tfv
            val tfunkind = substTfunkind subst tfunkind
            val _ = tfv := tfunkind
          in
            T.TFUN_VAR tfv
          end
      | T.TFUN_VAR (tfv as ref (tfunkind as (T.TFV_DTY _))) => 
        if isVisited tfv then T.TFUN_VAR tfv
        else
          let
            val _ = visit tfv;
            val tfunkind = substTfunkind subst tfunkind
            val _ = tfv := tfunkind
          in
            T.TFUN_VAR tfv
          end
      | T.TFUN_VAR (tfv as ref (tfunkind as (T.TFUN_DTY _))) => 
        if isVisited tfv then T.TFUN_VAR tfv
        else
          let
            val _ = visit tfv;
            val tfunkind = substTfunkind subst tfunkind
            val _ = tfv := tfunkind
          in
            T.TFUN_VAR tfv
          end
      | T.TFUN_VAR (tfv as ref (T.INSTANTIATED{tfunkind, tfun})) => 
        let
          val tfunkind = substTfunkind subst tfunkind
          val tfun = substTfun subst tfun
          val _ = tfv := T.INSTANTIATED{tfunkind=tfunkind, tfun=tfun}
        in
          T.TFUN_VAR tfv
        end
      | T.TFUN_VAR _ => tfun
    and substTy (subst:subst as {tvarS,...}) (ty:T.ty) : T.ty =
        case ty of
          T.TYWILD => ty
        | T.TYVAR (tvar) => 
          (case TvarMap.find(tvarS, tvar) of
             SOME ty => ty
           | NONE => ty
          )
        | T.TYRECORD fields =>
          T.TYRECORD (SEnv.map (substTy subst) fields)
        | T.TYCONSTRUCT {typ, args} =>
          T.TYCONSTRUCT
            {typ=substTypInfo subst typ,
             args=map (substTy subst) args
            }
        | T.TYFUNM (tyList, ty2) =>
          T.TYFUNM (map (substTy subst) tyList, substTy subst ty2)
        | T.TYPOLY (kindedTvarList, ty) =>
          T.TYPOLY (map (substKindedTvar subst) kindedTvarList, 
                    substTy subst ty
                   )
        | T.TYERROR => T.TYERROR
    and substTypInfo (subst:subst) {path, tfun} =
        {path=path, tfun=substTfun subst tfun}
    and substKindedTvar subst  (tvar, tvarKind) =
        (tvar, substKind subst tvarKind)
    and substKind subst tvarKind
      = case tvarKind of
          T.UNIV => T.UNIV
        | T.REC fields => T.REC (SEnv.map (substTy subst) fields)
    (* here we only substitute conid; this is to refresh conid *)
    (* subst is also used for instantiation where we need to substitute
       conidstatus including ty *)
    fun substConId (subst:subst) id =
        case ConID.Map.find(#conIdS subst, id) of
          SOME (T.IDCON{id,ty}) => id
        | SOME _ => raise bug "substConId"
        | NONE => id
    fun substExnId (subst:subst)  id =
        case ExnID.Map.find(#exnIdS subst, id) of
          SOME newId => newId
        | NONE => id
    fun substIdstatus subst idstatus = 
        case idstatus of
          T.IDVAR varId => idstatus
        | T.IDEXVAR {path, ty} => T.IDEXVAR {path=path, ty=substTy subst ty}
        | T.IDBUILTINVAR {primitive, ty} =>
          T.IDBUILTINVAR {primitive=primitive, ty=substTy subst ty}
        | T.IDCON {id, ty} => 
          T.IDCON {id=substConId subst id, ty=substTy subst ty}
        | T.IDEXN {id, ty} =>
          T.IDEXN {id=substExnId subst id, ty=substTy subst ty}
        | T.IDEXNREP {id, ty} =>
          T.IDEXNREP {id=substExnId subst id, ty=substTy subst ty}
        | T.IDEXEXN {path, ty} => T.IDEXEXN {path=path, ty=substTy subst ty}
        | T.IDOPRIM oprimId => idstatus
        | T.IDSPECVAR ty => T.IDSPECVAR (substTy subst ty)
        | T.IDSPECEXN ty => T.IDSPECEXN (substTy subst ty)
        | T.IDSPECCON => idstatus
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
          | IV.TSTR_TOTVAR {id, iseq, tvar} => 
            case TvarMap.find(tvarS, tvar) of
              SOME ty =>
              let
                val tfun = T.TFUN_DEF{iseq=iseq, formals=nil, realizerTy=ty}
              in
                IV.TSTR tfun
              end
            | NONE => tstr
        end
    fun substTyE subst tyE = SEnv.map (substTstr subst) tyE
    fun substEnv subst (IV.ENV {varE, tyE, strE}) =
        IV.ENV
          {varE = substVarE subst varE,
           tyE = substTyE subst tyE,
           strE = substStrE subst strE
          }
    and substStrE subst (IV.STR specEnvMap) =
        IV.STR (SEnv.map (substEnv subst) specEnvMap)
  
  in
    val substEnv = fn subst => fn env => (resetSet(); substEnv subst env)
    val substTy = fn subst => fn ty => (resetSet(); substTy subst ty)
    val substVarE = fn subst => fn varE => (resetSet(); substVarE subst varE)
  end

  fun substTfvTfun tfvSubst tfun = 
      case T.derefTfun tfun of
        T.TFUN_DEF {iseq, formals, realizerTy} =>
        T.TFUN_DEF {iseq=iseq,
                    formals=formals,
                    realizerTy=substTfvTy tfvSubst realizerTy}
      | T.TFUN_VAR (tfv as ref (T.TFV_SPEC _)) =>
        (case TfvMap.find(tfvSubst, tfv) of
           NONE => tfun
         | SOME tfv => T.TFUN_VAR tfv
        )
      | T.TFUN_VAR (tfv as ref (T.TFV_DTY _)) => 
        (case TfvMap.find(tfvSubst, tfv) of
           NONE => tfun
         | SOME tfv => T.TFUN_VAR tfv
        )
      | T.TFUN_VAR (tfv as ref (T.TFUN_DTY _)) => 
        (case TfvMap.find(tfvSubst, tfv) of
           NONE => tfun
         | SOME tfv => T.TFUN_VAR tfv
        )
      | T.TFUN_VAR _ => tfun

  and substTfvTy (tfvSubst:tfvSubst) (ty:T.ty) : T.ty =
      case ty of
        T.TYWILD => ty
      | T.TYVAR tvar => ty
      | T.TYRECORD fields =>
        T.TYRECORD (SEnv.map (substTfvTy tfvSubst) fields)
      | T.TYCONSTRUCT {typ, args} =>
        T.TYCONSTRUCT
          {typ=substTfvTypInfo tfvSubst typ,
           args=map (substTfvTy tfvSubst) args
          }
      | T.TYFUNM (tyList, ty2) =>
        T.TYFUNM (map (substTfvTy tfvSubst) tyList, substTfvTy tfvSubst ty2)
      | T.TYPOLY (kindedTvarList, ty) =>
        T.TYPOLY (map (substTfvKindedTvar tfvSubst) kindedTvarList, 
                  substTfvTy tfvSubst ty
                 )
      | T.TYERROR => T.TYERROR

  and substTfvTypInfo (tfvSubst:tfvSubst) {path, tfun} =
      {path=path, tfun=substTfvTfun tfvSubst tfun}

  and substTfvKindedTvar tfvSubst  (tvar, tvarKind) =
      (tvar, substTfvKind tfvSubst tvarKind)

  and substTfvKind tfvSubst tvarKind
    = case tvarKind of
        T.UNIV => T.UNIV
      | T.REC fields => T.REC (SEnv.map (substTfvTy tfvSubst) fields)

  fun substTfvIdstatus tfvSubst idstatus = 
      case idstatus of
        T.IDVAR varId => idstatus
      | T.IDEXVAR {path, ty} => T.IDEXVAR {path=path, ty=substTfvTy tfvSubst ty}
      | T.IDBUILTINVAR {primitive, ty} =>
        T.IDBUILTINVAR {primitive=primitive, ty=substTfvTy tfvSubst ty}
      | T.IDCON {id, ty} => T.IDCON {id=id, ty=substTfvTy tfvSubst ty}
      | T.IDEXN {id, ty} => T.IDEXN {id=id, ty=substTfvTy tfvSubst ty}
      | T.IDEXNREP {id, ty} => T.IDEXNREP {id=id, ty=substTfvTy tfvSubst ty}
      | T.IDEXEXN {path, ty} => T.IDEXEXN {path=path, ty=substTfvTy tfvSubst ty}
      | T.IDOPRIM oprimId => idstatus
      | T.IDSPECVAR ty => T.IDSPECVAR (substTfvTy tfvSubst ty)
      | T.IDSPECEXN ty => T.IDSPECEXN(substTfvTy tfvSubst ty)
      | T.IDSPECCON => idstatus

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
      | IV.TSTR_TOTVAR {id, iseq, tvar} => tstr

  fun substTfvTyE tfvSubst tyE = SEnv.map (substTfvTstr tfvSubst) tyE

  fun substTfvEnv tfvSubst (IV.ENV {varE, tyE, strE}) =
      IV.ENV
        {varE = substTfvVarE tfvSubst varE,
         tyE = substTfvTyE tfvSubst tyE,
         strE = substTfvStrE tfvSubst strE
        }
  and substTfvStrE tfvSubst (IV.STR specEnvMap) =
      IV.STR (SEnv.map (substTfvEnv tfvSubst) specEnvMap)


end
end
