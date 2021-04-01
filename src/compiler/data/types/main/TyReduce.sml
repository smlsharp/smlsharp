(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori 
 *)
structure TyReduce =
struct
local
  structure T = Types
  structure TU = TypesBasics
  (* structure P = TyPrinters *)
  type ty = T.ty
  type varInfo = T.varInfo
  type longsymbol = Symbol.longsymbol
  type btv = BoundTypeVarID.id
  fun bug s = Bug.Bug ("TyReduce: " ^ s)
in
  type btvMap = ty BoundTypeVarID.Map.map
  val emptyBtvMap = BoundTypeVarID.Map.empty : btvMap

  fun evalBtv (btvMap:btvMap) (btv:btv) : ty =
       case BoundTypeVarID.Map.find(btvMap, btv) of
         NONE => T.BOUNDVARty btv
       | SOME ty => TyAlphaRename.copyTy TyAlphaRename.emptyBtvMap ty

  val foo = evalBtv
  fun evalSingletonTy (btvMap:btvMap) (singletonTy:T.singletonTy) : T.singletonTy =
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
           match = evalOverloadMatch btvMap match
          }
      | T.INDEXty (string, ty) => T.INDEXty (string, evalTy btvMap ty)
      | T.TAGty ty => T.TAGty (evalTy btvMap ty)
      | T.SIZEty ty => T.SIZEty (evalTy btvMap ty)
      | T.REIFYty ty => T.REIFYty (evalTy btvMap ty)
  and evalOverloadMatch (btvMap:btvMap) (overloadMatch:T.overloadMatch) 
      : T.overloadMatch =
      case overloadMatch  of
        T.OVERLOAD_EXVAR {exVarInfo, instTyList} =>
        T.OVERLOAD_EXVAR
          {exVarInfo = evalExVarInfo btvMap exVarInfo,
           instTyList = Option.map (map (evalTy btvMap)) instTyList
          }
       | T.OVERLOAD_PRIM {primInfo, instTyList} =>
         T.OVERLOAD_PRIM
           {
            primInfo = evalPrimInfo btvMap primInfo,
            instTyList = Option.map (map (evalTy btvMap)) instTyList
           }
       | T.OVERLOAD_CASE (ty, map:T.overloadMatch TypID.Map.map) =>
         T.OVERLOAD_CASE
           (evalTy btvMap ty,
            TypID.Map.map (evalOverloadMatch btvMap) map
           )
  and evalBackendTy btvMap backendTy =
      case backendTy of
        T.RECORDSIZEty ty =>
        T.RECORDSIZEty (evalTy btvMap ty)
      | T.RECORDBITMAPINDEXty (i, ty) =>
        T.RECORDBITMAPINDEXty (i, evalTy btvMap ty)
      | T.RECORDBITMAPty (i, ty) =>
        T.RECORDBITMAPty (i, evalTy btvMap ty)
      | T.CCONVTAGty codeEntryTy =>
        T.CCONVTAGty (evalCodeEntryTy btvMap codeEntryTy)
      | T.FUNENTRYty codeEntryTy =>
        T.FUNENTRYty (evalCodeEntryTy btvMap codeEntryTy)
      | T.CALLBACKENTRYty {tyvars, haveClsEnv, argTyList, retTy, attributes} =>
        T.CALLBACKENTRYty
          {tyvars = evalBtvEnv btvMap tyvars,
           haveClsEnv = haveClsEnv,
           argTyList = map (evalTy btvMap) argTyList,
           retTy = Option.map (evalTy btvMap) retTy,
           attributes = attributes}
      | T.SOME_FUNENTRYty => T.SOME_FUNENTRYty
      | T.SOME_FUNWRAPPERty => T.SOME_FUNWRAPPERty
      | T.SOME_CLOSUREENVty => T.SOME_CLOSUREENVty
      | T.SOME_CCONVTAGty => T.SOME_CCONVTAGty
      | T.FOREIGNFUNPTRty {argTyList, varArgTyList, resultTy, attributes} =>
        T.FOREIGNFUNPTRty
          {argTyList = map (evalTy btvMap) argTyList,
           varArgTyList = Option.map (map (evalTy btvMap)) varArgTyList,
           resultTy = Option.map (evalTy btvMap) resultTy,
           attributes = attributes}
  and evalCodeEntryTy btvMap {tyvars, haveClsEnv, argTyList, retTy} =
      {tyvars = evalBtvEnv btvMap tyvars,
       haveClsEnv = haveClsEnv,
       argTyList = map (evalTy btvMap) argTyList,
       retTy = evalTy btvMap retTy}
  and evalExVarInfo (btvMap:btvMap) {path:longsymbol,ty:ty} : T.exVarInfo =
      {path=path, ty=evalTy btvMap ty}
  and evalPrimInfo (btvMap:btvMap) ({primitive, ty}:T.primInfo) : T.primInfo =
      {primitive=primitive, ty=evalTy btvMap ty}
  and evalOprimInfo (btvMap:btvMap) ({ty, path, id}:T.oprimInfo) : T.oprimInfo =
      {ty=evalTy btvMap ty, path=path,id=id}
  and evalConInfo (btvMap:btvMap) ({path, ty, id}:T.conInfo) : T.conInfo =
      {path=path, ty=evalTy btvMap ty, id=id}
  and evalExnInfo (btvMap:btvMap) ({path, ty, id}:T.exnInfo) : T.exnInfo =
      {path=path, ty=evalTy btvMap ty, id=id}
  and evalExExnInfo (btvMap:btvMap) ({path, ty}:T.exExnInfo) : T.exExnInfo =
      {path=path, ty=evalTy btvMap ty}
  and evalTy (btvMap:btvMap) (ty:ty) : ty =
      case TU.derefTy ty of
        T.SINGLETONty singletonTy =>
        T.SINGLETONty (evalSingletonTy btvMap singletonTy)
      | T.BACKENDty backendTy =>
        T.BACKENDty (evalBackendTy btvMap backendTy)
      | T.ERRORty => 
        ty
      | T.DUMMYty (id, kind) =>
        T.DUMMYty (id, evalKind btvMap kind)
      | T.EXISTty (id, kind) =>
        T.EXISTty (id, evalKind btvMap kind)
      | T.TYVARty _ => raise bug "TYVARty in Optimize"
      | T.BOUNDVARty btv => 
        evalBtv btvMap btv
      | T.FUNMty (tyList, ty) =>
        T.FUNMty (map (evalTy btvMap) tyList, evalTy btvMap ty)
      | T.RECORDty (fields:ty RecordLabel.Map.map) =>
        T.RECORDty (RecordLabel.Map.map (evalTy btvMap) fields)
      | T.CONSTRUCTty
          {
           tyCon =
           {id,
            longsymbol : longsymbol,
            admitsEq : bool,
            arity : int,
            conSet,
            conIDSet,
            extraArgs : ty list,
            dtyKind : T.dtyKind
           },
           args : ty list
          } =>
        T.CONSTRUCTty
          {
           tyCon =
           {id = id,
            longsymbol = longsymbol,
            admitsEq = admitsEq,
            arity = arity,
            conSet = conSet,
            conIDSet = conIDSet,
            extraArgs = map (evalTy btvMap) extraArgs,
            dtyKind = evalDtyKind btvMap dtyKind
           },
           args = map (evalTy btvMap) args
          }
      | T.POLYty
          {
           boundtvars : T.btvEnv,
           constraints : T.constraint list,
           body : ty
          } =>
        let
          val boundtvars = evalBtvEnv btvMap boundtvars
          val constraints = List.map (evalConstraint btvMap) constraints
        in
          T.POLYty
            {
             boundtvars = boundtvars,
             constraints = constraints,
             body =  evalTy btvMap body
            }
        end
  and evalConstraint btvMap (T.JOIN {res, args = (arg1, arg2), loc}) =
      T.JOIN {res = evalTy btvMap res,
              args = (evalTy btvMap arg1, evalTy btvMap arg2),
              loc=loc}
  and evalBtvEnv (btvMap:btvMap) (btvEnv:T.btvEnv) =
      BoundTypeVarID.Map.map (evalKind btvMap) btvEnv
  and evalKind (btvMap:btvMap) (T.KIND {tvarKind, properties, dynamicKind}) =
      T.KIND {tvarKind=evalTvarKind btvMap tvarKind,
              properties = properties,
              dynamicKind = dynamicKind
             }
  and evalTvarKind btvMap tvarKind =
      case tvarKind of
        T.OCONSTkind tyList =>
        T.OCONSTkind (map (evalTy btvMap) tyList)
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
          {instances = map (evalTy btvMap) instances,
           operators =
           map
             (fn {oprimId, longsymbol, match} =>
                 {oprimId=oprimId,
                  longsymbol=longsymbol,
                  match = evalOverloadMatch btvMap match}
             )
             operators
          }
      | T.UNIV => T.UNIV
      | T.REC (fields:ty RecordLabel.Map.map) =>
        T.REC (RecordLabel.Map.map (evalTy btvMap) fields)
  and evalDtyKind btvMap dtyKind =
      case dtyKind of
        T.DTY _ => dtyKind
      | T.OPAQUE {opaqueRep:T.opaqueRep, revealKey} =>
        T.OPAQUE {opaqueRep = evalOpaqueRep btvMap opaqueRep,
                  revealKey=revealKey}
      | T.INTERFACE opaqueRep =>
        T.INTERFACE (evalOpaqueRep btvMap opaqueRep)
  and evalOpaqueRep btvMap opaueRep =
      case opaueRep of
        T.TYCON
          {id,
           longsymbol : longsymbol,
           admitsEq : bool,
           arity : int,
           conSet,
           conIDSet,
           extraArgs : ty list,
           dtyKind : T.dtyKind
          } =>
        T.TYCON
          {id = id,
           longsymbol = longsymbol,
           admitsEq = admitsEq,
           arity = arity,
           conSet = conSet,
           conIDSet = conIDSet,
           extraArgs = map (evalTy btvMap) extraArgs,
           dtyKind = evalDtyKind btvMap dtyKind
          }
      | T.TFUNDEF {admitsEq, arity, polyTy} =>
        T.TFUNDEF {admitsEq=admitsEq,
                   arity=arity,
                   polyTy = evalTy btvMap polyTy}

  fun evalTyVar (btvMap:btvMap) ({id, ty, path, opaque}:varInfo) =
      {id=id, path=path, ty=evalTy btvMap ty, opaque=opaque}

  fun applyTys (btvMap:btvMap) (btvEnv:T.btvEnv, instTyList:ty list) : btvMap =
      let
        val btvList = BoundTypeVarID.Map.listKeys btvEnv
        val btvBinds = ListPair.zip (btvList, instTyList)
        val btvMap = 
            foldl
              (fn ((btv,ty), btvMap) =>
                  BoundTypeVarID.Map.insert(btvMap, btv, ty))
              btvMap
              btvBinds
      in
        btvMap
      end
end
end
