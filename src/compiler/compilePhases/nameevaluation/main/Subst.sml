(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)
(* the initial error code of this file : S-001 *)
structure Subst :
sig
  type tvarSubst
  type tfvSubst
  type conIdSubst
  type exnIdSubst
  type typIdSubst
  type subst
  val emptyConIdSubst : conIdSubst
  val emptyExnIdSubst : exnIdSubst
  val emptyTypIdSubst : typIdSubst
  val emptySubst : subst
  val emptyTvarSubst : tvarSubst
  val emptyTfvSubst : tfvSubst
  val substEnv : subst -> NameEvalEnv.env -> NameEvalEnv.env
  val substTy : subst -> IDCalc.ty -> IDCalc.ty
  val substTfunkind : subst -> IDCalc.tfunkind -> IDCalc.tfunkind
  val substTfvTy : tfvSubst -> IDCalc.ty -> IDCalc.ty
  val substTfvTfun : tfvSubst -> IDCalc.tfun -> IDCalc.tfun
  val substTfvVarE : tfvSubst -> NameEvalEnv.varE -> NameEvalEnv.varE
  val substTfvEnv : tfvSubst -> NameEvalEnv.env -> NameEvalEnv.env
end
=
struct
local
  structure U = NameEvalUtils
  structure I = IDCalc
  structure IV = NameEvalEnv
  fun bug s = Bug.Bug ("Subst: " ^ s)
in
  type tvarSubst = I.ty TvarMap.map
  type tfvSubst = (I.tfunkind ref) TfvMap.map
  type conIdSubst = I.idstatus ConID.Map.map
  type exnIdSubst = ExnID.id ExnID.Map.map
  type typIdSubst = TypID.id TypID.Map.map
  type subst = {tvarS:tvarSubst,
                exnIdS:exnIdSubst,
                conIdS:conIdSubst,
                typIdS:typIdSubst,
                newProvider:I.version option}
  val emptyTvarSubst : tvarSubst = TvarMap.empty
  val emptyTfvSubst : tfvSubst = TfvMap.empty
  val emptyConIdSubst : conIdSubst = ConID.Map.empty
  val emptyExnIdSubst : exnIdSubst = ExnID.Map.empty
  val emptyTypIdSubst : typIdSubst = TypID.Map.empty
  val emptySubst : subst = {tvarS=emptyTvarSubst,
                            exnIdS=emptyExnIdSubst,
                            conIdS=emptyConIdSubst,
                            typIdS = emptyTypIdSubst,
                            newProvider=NONE}
  local
    val visitedSet = ref (TfvSet.empty)
    fun resetSet () = visitedSet := TfvSet.empty
    fun visit tfv = visitedSet := TfvSet.add(!visitedSet, tfv)
    fun isVisited tfv = TfvSet.member(!visitedSet, tfv)
    (* here we only substitute conid; this is to refresh conid *)
    (* subst is also used for instantiation where we need to substitute
       conidstatus including ty *)
    fun substTypId ({typIdS, ...}:subst) id = 
        case TypID.Map.find(typIdS, id) of
          SOME id => id
        | NONE => id
    fun substConId (subst:subst) id =
        case ConID.Map.find(#conIdS subst, id) of
          SOME (I.IDCON {id,...}) => id
        | SOME _ => raise bug "substConId"
        | NONE => id
    fun substTfunkind subst tfunkind =
        case tfunkind of
          I.TFV_SPEC {longsymbol, id, admitsEq, formals} => tfunkind
        | I.TFV_DTY {longsymbol, id,admitsEq,formals,conSpec,liftedTys} =>
          I.TFV_DTY {id= substTypId subst id,
                     longsymbol=longsymbol,
                     admitsEq=admitsEq,
                     formals=formals,
                     conSpec=substConSpec subst conSpec,
                     liftedTys=liftedTys
                    }
        | I.FUN_DTY {tfun, longsymbol, varE,
                     formals,
                     conSpec,
                     liftedTys} =>
          I.FUN_DTY {tfun = substTfun subst tfun, 
                     longsymbol = longsymbol, 
                     varE = substVarE subst varE,
                     formals = formals,
                     conSpec = substConSpec subst conSpec,
                     liftedTys = liftedTys}
        | I.TFUN_DTY {id,admitsEq,formals,longsymbol,
                      conSpec,conIDSet, liftedTys,dtyKind} =>
          I.TFUN_DTY {id= substTypId subst id,
                      admitsEq=admitsEq,
                      formals=formals,
                      conSpec=substConSpec subst conSpec,
                      conIDSet = ConID.Set.map (substConId subst) conIDSet,
                      longsymbol=longsymbol,
                      liftedTys=liftedTys,
                      dtyKind=
                      case dtyKind of
                        I.DTY _ => dtyKind
                      | I.DTY_INTERFACE _ => dtyKind
                      | I.FUNPARAM _ => dtyKind
                      | I.OPAQUE {tfun,revealKey} =>
                        I.OPAQUE {tfun=substTfun subst tfun,
                                  revealKey=revealKey}
                      | I.INTERFACE tfun =>
                        I.INTERFACE (substTfun subst tfun)
                     }
        | I.REALIZED {id, tfun} => raise bug "REALIZED"
        | I.INSTANTIATED {tfunkind, tfun} => raise bug "REALIZED"
    and substConSpec subst conSpec =
        SymbolEnv.map
        (fn tyOpt => Option.map (substTy subst) tyOpt)
        conSpec
    and substTfun (subst:subst as {tvarS,...}) tfun = 
        case I.derefTfun tfun of
        I.TFUN_DEF {longsymbol, admitsEq, formals=nil, realizerTy=I.TYVAR tvar} =>
        (case TvarMap.find(tvarS, tvar) of
           SOME ty => I.TFUN_DEF{longsymbol=longsymbol, admitsEq=admitsEq, 
                                 formals=nil, realizerTy=ty}
         | NONE => I.TFUN_DEF {longsymbol=longsymbol, admitsEq=admitsEq, formals=nil, 
                               realizerTy=I.TYVAR tvar}
        )
      | I.TFUN_DEF {longsymbol, admitsEq, formals, realizerTy} =>
        I.TFUN_DEF {longsymbol=longsymbol,
                    admitsEq=admitsEq,
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
      | I.TFUN_VAR (tfv as ref (tfunkind as (I.FUN_DTY _))) => 
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
        | I.TYFREE_TYVAR freeTvar =>  ty
        | I.TYVAR (tvar) => 
          (case TvarMap.find(tvarS, tvar) of
             SOME ty => ty
           | NONE => ty
          )
        | I.TYRECORD {ifFlex, fields} =>
          I.TYRECORD {ifFlex=ifFlex, 
                      fields=RecordLabel.Map.map (substTy subst) fields}
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
          I.UNIV props => I.UNIV props
        | I.REC {properties, recordKind} => 
          I.REC {properties=properties,
                 recordKind = RecordLabel.Map.map (substTy subst) recordKind}
(*
        | I.REIFY => I.REIFY
        | I.BOXED => I.BOXED
        | I.UNBOXED => I.UNBOXED
*)

    and substExnId (subst:subst)  id =
        case ExnID.Map.find(#exnIdS subst, id) of
          SOME newId => newId
        | NONE => id
    and substExInfo subst {used, longsymbol, ty, version} =
        {used = ref (!used), longsymbol=longsymbol, ty=substTy subst ty,
         version = substVersion subst version}
    and substVersion ({newProvider, ...}:subst) version =
        case newProvider of
          NONE => version
        | SOME x => x
    and substIdstatus subst idstatus = 
        case idstatus of
          I.IDVAR _ => idstatus
        | I.IDVAR_TYPED _ => idstatus
        | I.IDEXVAR {exInfo, internalId, defRange} => 
          I.IDEXVAR {exInfo=substExInfo subst exInfo, 
                     defRange = defRange,
                     internalId=internalId}
        | I.IDEXVAR_TOBETYPED {longsymbol, id, version, defRange} =>
          I.IDEXVAR_TOBETYPED
            {longsymbol = longsymbol,
             id = id,
             defRange = defRange,
             version = substVersion subst version}
        | I.IDBUILTINVAR {primitive, ty, defRange} =>
          I.IDBUILTINVAR {primitive=primitive, defRange = defRange, ty=substTy subst ty}
        | I.IDCON {id, longsymbol, ty, defRange} => 
          I.IDCON {id=substConId subst id, 
                   defRange = defRange, longsymbol=longsymbol, ty=substTy subst ty}
        | I.IDEXN {id, longsymbol, ty, defRange} =>
          let
            val exnInfo = {id=substExnId subst id, longsymbol=longsymbol, 
                           defRange = defRange,
                           ty=substTy subst ty}
(*
            val _ = IV.exnConAdd (IV.EXN exnInfo)
*)
          in
            I.IDEXN exnInfo
          end
        | I.IDEXNREP {id, longsymbol, ty, defRange} =>
          I.IDEXNREP {id=substExnId subst id, longsymbol=longsymbol, defRange = defRange,
                      ty=substTy subst ty}
        | I.IDEXEXN {used, longsymbol, ty, version, defRange} => 
          I.IDEXEXN {used = ref (!used), longsymbol=longsymbol, defRange = defRange,
                     ty=substTy subst ty, version=substVersion subst version}
        | I.IDEXEXNREP {used, longsymbol, ty, version, defRange} => 
          I.IDEXEXNREP {used = ref (!used), longsymbol=longsymbol, defRange = defRange,
                        ty=substTy subst ty, version=substVersion subst version}
        | I.IDOPRIM {id, overloadDef, used, longsymbol, defRange} =>
          I.IDOPRIM {id=id, overloadDef=overloadDef, used = ref (!used), defRange = defRange,
                     longsymbol=longsymbol}
        | I.IDSPECVAR {ty, symbol, defRange} => 
          I.IDSPECVAR {ty=substTy subst ty, symbol=symbol, defRange=defRange}
        | I.IDSPECEXN {ty, symbol, defRange} => 
          I.IDSPECEXN {ty=substTy subst ty, symbol=symbol, defRange=defRange}
        | I.IDSPECCON {symbol, defRange} => I.IDSPECCON {symbol=symbol, defRange = defRange} 
    and substVarE subst varE = SymbolEnv.map (substIdstatus subst) varE
    fun substTstr subst tstr =
        let
          val {tvarS,...} = subst
        in
          case tstr of 
            IV.TSTR (tsr as {tfun, ...}) => IV.TSTR (tsr # {tfun = substTfun subst tfun})
          | IV.TSTR_DTY {tfun, varE, formals, defRange, conSpec} =>
            IV.TSTR_DTY {tfun=substTfun subst tfun,
                         varE=substVarE subst varE,
                         formals=formals,
                         defRange = defRange,
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
        IV.STR 
          (SymbolEnv.map
             (fn strEntry as {env, ...} => strEntry # {env=substEnv subst env})
             specEnvMap)
  
  in
    val substEnv = fn subst => fn env => (resetSet(); substEnv subst env)
    val substTy = fn subst => fn ty => (resetSet(); substTy subst ty)
    val substTfunkind = fn subst => fn ty => (resetSet(); substTfunkind subst ty)
    val substVarE = fn subst => fn varE => (resetSet(); substVarE subst varE)
  end

  fun substTfvTfun tfvSubst tfun = 
      case I.derefTfun tfun of
        I.TFUN_DEF {longsymbol, admitsEq, formals, realizerTy} =>
        I.TFUN_DEF {admitsEq=admitsEq,
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
      | I.TFUN_VAR 
          (tfv 
             as
             ref (I.FUN_DTY {tfun=interTfun, longsymbol, varE, formals,conSpec, liftedTys})) => 
        (
         tfv := 
              I.FUN_DTY {tfun= substTfvTfun tfvSubst interTfun, 
                         longsymbol = longsymbol, 
                         varE = varE, 
                         formals = formals,
                         conSpec = conSpec, 
                         liftedTys = liftedTys};
         tfun
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
      | I.TYFREE_TYVAR freeTvar => ty
      | I.TYRECORD {ifFlex, fields} =>
        I.TYRECORD {ifFlex=ifFlex, 
                    fields= RecordLabel.Map.map (substTfvTy tfvSubst) fields}
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
        I.UNIV props => I.UNIV props
      | I.REC {properties, recordKind} => 
        I.REC {properties=properties,
               recordKind = RecordLabel.Map.map (substTfvTy tfvSubst) recordKind}

(*
      | I.REIFY => I.REIFY
      | I.BOXED => I.BOXED
      | I.UNBOXED => I.UNBOXED
*)

  and substTfvIdstatus tfvSubst idstatus = 
      case idstatus of
        I.IDVAR varId => idstatus
      | I.IDVAR_TYPED {id, longsymbol, ty, defRange} => 
        I.IDVAR_TYPED {id=id, longsymbol=longsymbol, defRange = defRange, ty=substTfvTy tfvSubst ty}
      | I.IDEXVAR {exInfo={used, longsymbol, version, ty}, internalId, defRange} => 
        I.IDEXVAR {exInfo = {used = used, longsymbol=longsymbol, 
                             version=version, ty = substTfvTy tfvSubst ty},
                   defRange = defRange,
                   internalId=internalId}
      | I.IDEXVAR_TOBETYPED _ => idstatus
      | I.IDBUILTINVAR {primitive, ty, defRange} =>
        I.IDBUILTINVAR {primitive=primitive, ty=substTfvTy tfvSubst ty, defRange = defRange}
      | I.IDCON {id, longsymbol, ty, defRange} =>
        I.IDCON {id=id, longsymbol=longsymbol, ty=substTfvTy tfvSubst ty, defRange = defRange}
      | I.IDEXN {id, longsymbol, ty, defRange} => 
        I.IDEXN {id=id, longsymbol=longsymbol, ty=substTfvTy tfvSubst ty, defRange = defRange}
      | I.IDEXNREP {id, longsymbol, ty, defRange} => 
        I.IDEXNREP {id=id, longsymbol=longsymbol, ty=substTfvTy tfvSubst ty, defRange = defRange}
      | I.IDEXEXN {used, longsymbol, ty, version, defRange} => 
        I.IDEXEXN {used = used, longsymbol=longsymbol, defRange = defRange,
                   ty=substTfvTy tfvSubst ty, version=version}
      | I.IDEXEXNREP {used, longsymbol, ty, version, defRange} => 
        I.IDEXEXNREP {used = used, longsymbol=longsymbol, defRange = defRange,
                      ty=substTfvTy tfvSubst ty, version=version}
      | I.IDOPRIM _ => idstatus
      | I.IDSPECVAR {ty, symbol, defRange} => 
        I.IDSPECVAR {ty=substTfvTy tfvSubst ty, symbol=symbol, defRange = defRange}
      | I.IDSPECEXN {ty, symbol, defRange} => 
        I.IDSPECEXN {ty=substTfvTy tfvSubst ty, symbol=symbol, defRange = defRange}
      | I.IDSPECCON {symbol, defRange} => I.IDSPECCON {symbol=symbol, defRange = defRange}

  and substTfvVarE tfvSubst varE = SymbolEnv.map (substTfvIdstatus tfvSubst) varE

  fun substTfvTstr tfvSubst tstr = 
      case tstr of 
        IV.TSTR (tsr as {tfun, ...}) => 
        IV.TSTR (tsr # {tfun = substTfvTfun tfvSubst tfun})
      | IV.TSTR_DTY {tfun, varE, formals, defRange,conSpec} =>
        IV.TSTR_DTY {tfun=substTfvTfun tfvSubst tfun,
                     varE=substTfvVarE tfvSubst varE,
                     defRange = defRange,formals=formals,
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
           (fn strEntry as {env, ...} => 
               strEntry # {env=substTfvEnv tfvSubst env}) 
           specEnvMap)
end
end
