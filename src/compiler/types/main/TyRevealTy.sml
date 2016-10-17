structure TyRevealTy = 
struct
local
  structure U = Unify
  structure T = Types
  structure TU = TypesBasics
  type ty = T.ty
  type longsymbol = Symbol.longsymbol
  type varInfo = T.varInfo
  fun bug s = Bug.Bug ("TyRevealTy: " ^ s)
in
  fun revealSingletonTy (singletonTy:T.singletonTy) : T.singletonTy =
      case singletonTy of
        T.INSTCODEty
          {
           oprimId,
           longsymbol,
           keyTyList : ty list,
           match : T.overloadMatch,
           instMap : T.overloadMatch OPrimInstMap.map
          } =>
        T.INSTCODEty
          {
           oprimId=oprimId,
           longsymbol=longsymbol,
           keyTyList = map revealTy keyTyList,
           match = revealOverloadMatch match,
           instMap = OPrimInstMap.map revealOverloadMatch instMap
          }
      | T.INDEXty (string, ty) => T.INDEXty (string, revealTy ty)
      | T.TAGty ty => T.TAGty (revealTy ty)
      | T.SIZEty ty => T.SIZEty (revealTy ty)
  and revealOverloadMatch (overloadMatch:T.overloadMatch) : T.overloadMatch =
      case overloadMatch  of
        T.OVERLOAD_EXVAR {exVarInfo, instTyList} =>
        T.OVERLOAD_EXVAR
          {exVarInfo = revealExVarInfo exVarInfo,
           instTyList = map revealTy instTyList
          }
       | T.OVERLOAD_PRIM {primInfo, instTyList} =>
         T.OVERLOAD_PRIM
           {
            primInfo = revealPrimInfo primInfo,
            instTyList = map revealTy instTyList
           }
       | T.OVERLOAD_CASE (ty, map:T.overloadMatch TypID.Map.map) =>
         T.OVERLOAD_CASE
           (revealTy ty, TypID.Map.map revealOverloadMatch map)
  and revealExVarInfo {path:longsymbol,ty:ty} : T.exVarInfo =
      {path=path, ty=revealTy ty}
  and revealPrimInfo ({primitive, ty}:T.primInfo) : T.primInfo =
      {primitive=primitive, ty=revealTy ty}
  and revealOprimInfo ({ty, path, id}:T.oprimInfo) : T.oprimInfo =
      {ty=revealTy ty, path=path, id=id}
  and revealConInfo ({path, ty, id}:T.conInfo) : T.conInfo =
      {path=path, ty=revealTy ty, id=id}
  and revealExnInfo ({path, ty, id}:T.exnInfo) : T.exnInfo =
      {path=path, ty=revealTy ty, id=id}
  and revealExExnInfo ({path, ty}:T.exExnInfo) : T.exExnInfo =
      {path=path, ty=revealTy ty}
  and revealTyCon
        {id : T.typId,
         longsymbol : longsymbol,
         iseq : bool,
         arity : int,
         runtimeTy : BuiltinTypeNames.bty,
         conSet,
         conIDSet,
         extraArgs : ty list,
         dtyKind : T.dtyKind
        } =
        {id = id,
         longsymbol = longsymbol,
         iseq = iseq,
         arity = arity,
         runtimeTy = runtimeTy,
         conSet = conSet,
         conIDSet = conIDSet,
         extraArgs = map revealTy extraArgs,
         dtyKind = revealDtyKind dtyKind
        }
  and revealDtyKind dtyKind =
      case dtyKind of
        T.DTY => dtyKind
      | T.OPAQUE {opaqueRep:T.opaqueRep, revealKey:T.revealKey} =>
        T.OPAQUE {opaqueRep = revealOpaqueRep opaqueRep,
                  revealKey=revealKey}
      | T.BUILTIN bty => dtyKind
  and revealOpaqueRep opaueRep =
      case opaueRep of
        T.TYCON tyCon  =>T.TYCON (revealTyCon tyCon)
      | T.TFUNDEF {iseq, arity, polyTy} =>
        T.TFUNDEF {iseq=iseq,
                   arity=arity,
                   polyTy = revealTy polyTy}
  and revealTy (ty:ty) : ty =
      case TU.derefTy ty of
        T.SINGLETONty singletonTy =>
        T.SINGLETONty (revealSingletonTy singletonTy)
      | T.BACKENDty backendTy =>
        raise Bug.Bug "revealTy: BACKENDty"
      | T.ERRORty => ty
      | T.DUMMYty dummyTyID => ty
      | T.DUMMY_RECORDty _ => ty
      | T.TYVARty _ => raise bug "TYVARty in Optimize"
      | T.BOUNDVARty btv => ty
      | T.FUNMty (tyList, ty) =>
        T.FUNMty (map revealTy tyList, revealTy ty)
      | T.RECORDty (fields:ty RecordLabel.Map.map) =>
        T.RECORDty (RecordLabel.Map.map revealTy fields)
      | T.CONSTRUCTty {tyCon, args} =>
        let
          val tyCon
                as 
                {id : T.typId,
                 longsymbol : longsymbol,
                 iseq : bool,
                 arity : int,
                 runtimeTy : BuiltinTypeNames.bty,
                 conSet,
                 conIDSet,
                 extraArgs : ty list,
                 dtyKind : T.dtyKind
                } = revealTyCon tyCon
          val args = map revealTy args
        in
          case dtyKind of
            T.OPAQUE{opaqueRep,revealKey} =>
            (case opaqueRep of
               T.TYCON tyCon =>
               T.CONSTRUCTty{tyCon=tyCon, args= args}
             | T.TFUNDEF {iseq, arity, polyTy} =>
               U.instOfPolyTy(polyTy, args)
            )
          | T.DTY => T.CONSTRUCTty{tyCon=tyCon, args= args}
          | T.BUILTIN bty => T.CONSTRUCTty{tyCon=tyCon, args= args}
        end
      | T.POLYty {boundtvars : T.btvEnv, constraints : T.constraint list, body : ty } =>
        T.POLYty {boundtvars = revealBtvEnv boundtvars, 
                  constraints = List.map (fn c =>
                                             case c of T.JOIN {res, args = (arg1, arg2)} =>
                                               T.JOIN
                                                   {res = revealTy res,
                                                    args = (revealTy arg1,
                                                            revealTy arg2)})
                                         constraints,
                  body =  revealTy body}
  and revealBtvEnv (btvEnv:T.btvEnv) =
      BoundTypeVarID.Map.map revealBtvkind btvEnv
  and revealBtvkind {tvarKind, eqKind} =
      {tvarKind=revealTvarKind tvarKind, eqKind=eqKind}
  and revealTvarKind tvarKind =
      case tvarKind of
        T.OCONSTkind tyList =>
        T.OCONSTkind (map revealTy tyList)
      | T.OPRIMkind
          {instances:ty list,
           operators:
           {
            oprimId : OPrimID.id,
            longsymbol : longsymbol,
            keyTyList : ty list,
            match : T.overloadMatch,
            instMap : T.overloadMatch OPrimInstMap.map
           } list
          } =>
        T.OPRIMkind
          {instances = map revealTy instances,
           operators =
           map
             (fn {oprimId, longsymbol, keyTyList, match, instMap} =>
                 {oprimId=oprimId,
                  longsymbol=longsymbol,
                  keyTyList = map revealTy keyTyList,
                  match = revealOverloadMatch match,
                  instMap = OPrimInstMap.map revealOverloadMatch instMap}
             )
             operators
          }
      | T.UNIV => T.UNIV
      | T.JSON => T.JSON
      | T.BOXED => T.BOXED
      | T.UNBOXED => T.UNBOXED
      | T.REC (fields:ty RecordLabel.Map.map) =>
        T.REC (RecordLabel.Map.map revealTy fields)
  fun revealVar ({id, ty, path, opaque}:varInfo) =
      {id=id, path=path, ty=revealTy ty, opaque=opaque}
end
end
