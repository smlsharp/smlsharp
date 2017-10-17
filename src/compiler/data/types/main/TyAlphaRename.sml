structure TyAlphaRename =
struct
local
  structure T = Types
  structure TU = TypesBasics
  structure P = TyPrinters

  fun bug s = Bug.Bug ("AlphaRename: " ^ s)

  exception DuplicateBtv

  type ty = T.ty
  type longsymbol = Symbol.longsymbol
  type btvEnv = T.kind BoundTypeVarID.Map.map

  type btvMap = BoundTypeVarID.id BoundTypeVarID.Map.map
  val emptyBtvMap = BoundTypeVarID.Map.empty

  fun printBtvMap btvMap =
      let
        val _ = P.print "printBtvMap\n"
        fun pr (id, id2) = 
            (P.print "(";
             P.print (BoundTypeVarID.toString id);
             P.print ",";
             P.print (BoundTypeVarID.toString id2);
             P.print ")\n"
            )
      in
        BoundTypeVarID.Map.appi pr btvMap
      end

  (* alpha-rename types *)
  fun evalBtv (btvMap:btvMap) btv =
      case BoundTypeVarID.Map.find(btvMap, btv) of
        SOME btv => btv
      | NONE => btv

  fun newBtv (btvMap:btvMap) btv =
      let
        val newBtv = BoundTypeVarID.generate()
        val btvMap =
            BoundTypeVarID.Map.insertWith
              (fn _ => raise DuplicateBtv)
              (btvMap, btv, newBtv)
      in
        (btvMap, newBtv)
      end
  fun newBtvEnv (btvMap:btvMap) btvEnv =
      let
        val _ = P.print "newBtvEnv\n"
        val _ = printBtvMap emptyBtvMap
        val _ = P.print "print emptyBtvMap\n"
        val _ = printBtvMap btvMap
        val _ = P.print "print newBtvMap\n"
        val (btvMap, btvEnv) =
            BoundTypeVarID.Map.foldli  
            (* we cannot use foldri here; we must preserve the order of btv *)
            (fn (btv, btvkind, (btvMap, btvEnv)) =>
                let
                  val (btvMap, newBtv) = newBtv btvMap btv
                  val btvEnv = BoundTypeVarID.Map.insert(btvEnv, newBtv, btvkind)
                in
                  (btvMap, btvEnv)
                end
            )
            (btvMap, BoundTypeVarID.Map.empty)
            btvEnv
        val btvEnv = BoundTypeVarID.Map.map (copyKind btvMap) btvEnv
      in
        (btvMap, btvEnv)
      end
  and copySingletonTy (btvMap:btvMap) singletonTy =
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
           keyTyList = map (copyTy btvMap) keyTyList,
           match = copyOverloadMatch btvMap match,
           instMap = OPrimInstMap.map (copyOverloadMatch btvMap) instMap
          }
      | T.INDEXty (string, ty) => T.INDEXty (string, copyTy btvMap ty)
      | T.TAGty ty => T.TAGty (copyTy btvMap ty)
      | T.SIZEty ty => T.SIZEty (copyTy btvMap ty)
      | T.TYPEty ty => T.TYPEty (copyTy btvMap ty)
      | T.REIFYty ty => T.TYPEty (copyTy btvMap ty)
  and copyOverloadMatch (btvMap:btvMap) overloadMatch =
      case overloadMatch  of
        T.OVERLOAD_EXVAR {exVarInfo, instTyList} =>
         T.OVERLOAD_EXVAR
           {exVarInfo = copyExVarInfo btvMap exVarInfo,
            instTyList = map (copyTy btvMap) instTyList
           }
       | T.OVERLOAD_PRIM {primInfo, instTyList} =>
         T.OVERLOAD_PRIM
           {
            primInfo = copyPrimInfo btvMap primInfo,
            instTyList = map (copyTy btvMap) instTyList
           }
       | T.OVERLOAD_CASE (ty, map:T.overloadMatch TypID.Map.map) =>
         T.OVERLOAD_CASE
         (copyTy btvMap ty,
         TypID.Map.map (copyOverloadMatch btvMap) map
         )
  and copyExVarInfo btvMap {path:longsymbol, ty:ty} =
      {path=path, ty=copyTy btvMap ty}
  and copyPrimInfo btvMap {primitive : BuiltinPrimitive.primitive, ty : ty} =
      {primitive=primitive, ty=copyTy btvMap ty}
  and copyTy (btvMap:btvMap) ty =
      let
        val _ = P.print "*** copyTy ***"
        val _ = P.printTy ty
      in
      case TU.derefTy ty of
        T.SINGLETONty singletonTy =>
        T.SINGLETONty (copySingletonTy btvMap singletonTy)
      | T.BACKENDty backendTy =>
        raise Bug.Bug "copyTy: BACKENDty"
      | T.ERRORty => 
         ty
      | T.DUMMYty (dummyTyID, kind) => 
        T.DUMMYty (dummyTyID, copyKind btvMap kind)
      | T.TYVARty _ => raise bug "TYVARty in AlphaRename"
      | T.BOUNDVARty btv => 
        T.BOUNDVARty (evalBtv btvMap btv)
      | T.FUNMty (tyList, ty) =>
        T.FUNMty (map (copyTy btvMap) tyList, copyTy btvMap ty)
      | T.RECORDty (fields:ty RecordLabel.Map.map) =>
        T.RECORDty (RecordLabel.Map.map (copyTy btvMap) fields)
      | T.CONSTRUCTty
          {
           tyCon =
           {id : T.typId,
            longsymbol : longsymbol,
            iseq : bool,
            arity : int,
            runtimeTy : BuiltinTypeNames.bty,
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
            iseq = iseq,
            arity = arity,
            runtimeTy = runtimeTy,
            conSet = conSet,
            conIDSet = conIDSet,
            extraArgs = map (copyTy btvMap) extraArgs,
            dtyKind = copyDtyKind btvMap dtyKind
           },
           args = map (copyTy btvMap) args
          }
      | T.POLYty
          {
           boundtvars : T.btvEnv,
           constraints : T.constraint list,
           body : ty
          } =>
        let
          val _ = P.print "polyTy\n"
          val (btvMap, boundtvars) = newBtvEnv btvMap boundtvars
          val constraints = List.map
                                (fn c =>
                                    case c of T.JOIN {res, args = (arg1, arg2), loc} =>
                                      T.JOIN
                                          {res = copyTy btvMap res,
                                           args = (copyTy btvMap arg1,
                                                   copyTy btvMap arg2), loc=loc})
                                constraints
          val _ = P.print "newBtvEnv\n"
        in
          T.POLYty
            {
             boundtvars = boundtvars,
             constraints = constraints,
             body =  copyTy btvMap body
            }
        end
      end
  and copyKind btvMap (T.KIND {tvarKind, eqKind, dynKind, reifyKind, subkind}) =
      let
        val tvarKind = copyTvarKind btvMap tvarKind
      in
        T.KIND {tvarKind=tvarKind, eqKind=eqKind, subkind=subkind, dynKind=dynKind, reifyKind=reifyKind}
      end
  and copyTvarKind btvMap tvarKind =
      case tvarKind of
        T.OCONSTkind tyList =>
        T.OCONSTkind (map (copyTy btvMap) tyList)
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
          {instances = map (copyTy btvMap) instances,
           operators =
           map
             (fn {oprimId, longsymbol, keyTyList, match, instMap} =>
                 {oprimId=oprimId,
                  longsymbol=longsymbol,
                  keyTyList = map (copyTy btvMap) keyTyList,
                  match = copyOverloadMatch btvMap match,
                  instMap = OPrimInstMap.map (copyOverloadMatch btvMap) instMap}
             )
             operators
          }
      | T.UNIV => T.UNIV
      | T.BOXED => T.BOXED
      | T.REC (fields:ty RecordLabel.Map.map) =>
        T.REC (RecordLabel.Map.map (copyTy btvMap) fields)
  and copyDtyKind btvMap dtyKind =
      case dtyKind of
        T.DTY => dtyKind
      | T.OPAQUE {opaqueRep:T.opaqueRep, revealKey:T.revealKey} =>
        T.OPAQUE {opaqueRep = copyOpaqueRep btvMap opaqueRep,
                  revealKey=revealKey}
      | T.BUILTIN bty => dtyKind
  and copyOpaqueRep btvMap opaueRep =
      case opaueRep of
        T.TYCON
          {id : T.typId,
           longsymbol : longsymbol,
           iseq : bool,
           arity : int,
           runtimeTy : BuiltinTypeNames.bty,
           conSet,
           conIDSet,
           extraArgs : ty list,
           dtyKind : T.dtyKind
          } =>
        T.TYCON
          {id = id,
           longsymbol = longsymbol,
           iseq = iseq,
           arity = arity,
           runtimeTy = runtimeTy,
           conSet = conSet,
           conIDSet = conIDSet,
           extraArgs = map (copyTy btvMap) extraArgs,
           dtyKind = copyDtyKind btvMap dtyKind
          }
      | T.TFUNDEF {iseq, arity, polyTy} =>
        T.TFUNDEF {iseq=iseq,
                   arity=arity,
                   polyTy = copyTy btvMap polyTy}
in
  type btvMap = btvMap
  val emptyBtvMap = emptyBtvMap
  val copyTy = copyTy
  val newBtvEnv = newBtvEnv
end
end
