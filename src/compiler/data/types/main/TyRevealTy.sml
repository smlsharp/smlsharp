structure TyRevealTy = 
struct
local
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
           match : T.overloadMatch
          } =>
        T.INSTCODEty
          {
           oprimId=oprimId,
           longsymbol=longsymbol,
           match = revealOverloadMatch match
          }
      | T.INDEXty (string, ty) => T.INDEXty (string, revealTy ty)
      | T.TAGty ty => T.TAGty (revealTy ty)
      | T.SIZEty ty => T.SIZEty (revealTy ty)
      | T.REIFYty ty => T.REIFYty (revealTy ty)
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
        {id,
         longsymbol : longsymbol,
         admitsEq : bool,
         arity : int,
         conSet,
         conIDSet,
         extraArgs : ty list,
         dtyKind : T.dtyKind
        } =
        {id = id,
         longsymbol = longsymbol,
         admitsEq = admitsEq,
         arity = arity,
         conSet = conSet,
         conIDSet = conIDSet,
         extraArgs = map revealTy extraArgs,
         dtyKind = revealDtyKind dtyKind
        }
  and revealDtyKind dtyKind =
      case dtyKind of
        T.DTY _ => dtyKind
      | T.OPAQUE {opaqueRep:T.opaqueRep, revealKey} =>
        T.OPAQUE {opaqueRep = revealOpaqueRep opaqueRep,
                  revealKey=revealKey}
      | T.INTERFACE opaqueRep =>
        T.INTERFACE (revealOpaqueRep opaqueRep)
  and revealOpaqueRep opaueRep =
      case opaueRep of
        T.TYCON tyCon  =>T.TYCON (revealTyCon tyCon)
      | T.TFUNDEF {admitsEq, arity, polyTy} =>
        T.TFUNDEF {admitsEq=admitsEq,
                   arity=arity,
                   polyTy = revealTy polyTy}
  and revealTy (ty:ty) : ty =
      case TU.derefTy ty of
        T.SINGLETONty singletonTy =>
        T.SINGLETONty (revealSingletonTy singletonTy)
      | T.BACKENDty backendTy =>
        raise Bug.Bug "revealTy: BACKENDty"
      | T.ERRORty => ty
      | T.DUMMYty (id, kind) => T.DUMMYty (id, revealKind kind)
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
                {id,
                 longsymbol : longsymbol,
                 admitsEq : bool,
                 arity : int,
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
             | T.TFUNDEF {admitsEq, arity, polyTy} =>
               TU.tpappTy (polyTy, args)
            )
          | T.INTERFACE opaqueRep =>
            (case opaqueRep of
               T.TYCON tyCon =>
               T.CONSTRUCTty{tyCon=tyCon, args= args}
             | T.TFUNDEF {admitsEq, arity, polyTy} =>
               TU.tpappTy (polyTy, args)
            )
          | T.DTY _ => T.CONSTRUCTty{tyCon=tyCon, args= args}
        end
      | T.POLYty {boundtvars : T.btvEnv, constraints : T.constraint list, body : ty } =>
        T.POLYty {boundtvars = revealBtvEnv boundtvars, 
                  constraints = List.map revealConstraint constraints,
                  body =  revealTy body}
  and revealConstraint (T.JOIN {res, args = (arg1, arg2), loc}) =
      T.JOIN
        {res = revealTy res,
         args = (revealTy arg1, revealTy arg2),
         loc=loc}
  and revealBtvEnv (btvEnv:T.btvEnv) =
      BoundTypeVarID.Map.map revealKind btvEnv
  and revealKind (T.KIND {tvarKind, properties, dynamicKind}) =
      T.KIND {tvarKind=revealTvarKind tvarKind, properties = properties, dynamicKind = dynamicKind}
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
            match : T.overloadMatch
           } list
          } =>
        T.OPRIMkind
          {instances = map revealTy instances,
           operators = operators
(* do not reveal operators.
 * they use opaque tycon ids as a key of instance selector *)
(*
           map
             (fn {oprimId, longsymbol, match} =>
                 {oprimId=oprimId,
                  longsymbol=longsymbol,
                  match = revealOverloadMatch match}
             )
             operators
*)
          }
      | T.UNIV => T.UNIV
(*
      | T.BOXED => T.BOXED
      | T.UNBOXED => T.UNBOXED
*)
      | T.REC (fields:ty RecordLabel.Map.map) =>
        T.REC (RecordLabel.Map.map revealTy fields)
  fun revealVar ({id, ty, path, opaque}:varInfo) =
      {id=id, path=path, ty=revealTy ty, opaque=opaque}
end
end
