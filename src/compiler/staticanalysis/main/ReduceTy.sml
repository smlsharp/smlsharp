(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
structure ReduceTy = struct
  structure T = Types
  fun substTy (subst,ty) =
      case TypesUtils.derefTy ty of
      T.SINGLETONty singletonTy => T.SINGLETONty (substSingletonTy(subst, singletonTy))
    | T.ERRORty => ty
    | T.DUMMYty dummyTyID => ty
    | T.TYVARty tvStateRef => ty
    | T.BOUNDVARty id => 
      (case BoundTypeVarID.Map.find(subst, id) of
         SOME ty => ty
       | NONE => ty
      )
    | T.FUNMty (tylist, ty) => 
      T.FUNMty (map (fn ty => substTy(subst,ty)) tylist, 
                substTy(subst, ty)
               )
    | T.RECORDty tymap => T.RECORDty (LabelEnv.map (fn ty => substTy(subst, ty)) tymap)
    | T.CONSTRUCTty {tyCon as {arity,dtyKind,...}, args} =>
      let
        val args = map (fn ty => substTy(subst, ty)) args
      in
        T.CONSTRUCTty {tyCon=tyCon, args=args}
      end
    | T.POLYty {boundtvars, body} =>
      T.POLYty {boundtvars=boundtvars, body=substTy(subst,body)}
  and substSingletonTy (subst, ty) = 
      case ty of
      T.INSTCODEty oprimSelector => T.INSTCODEty (substoprimSelector (subst,oprimSelector))
    | T.INDEXty (string, ty) => T.INDEXty (string, substTy(subst, ty))
    | T.TAGty ty => T.TAGty (substTy(subst, ty))
    | T.SIZEty ty => T.SIZEty (substTy(subst, ty))
  and substoprimSelector (subst, {oprimId, path, keyTyList, match, instMap}) =
      {oprimId=oprimId, 
       path=path, 
       keyTyList=map (fn ty => substTy(subst,ty)) keyTyList, 
       match = substMatch(subst, match), 
       instMap = substInstMap (subst,instMap)}
  and substMatch (subst, match) =
      case match of
      T.OVERLOAD_EXVAR {exVarInfo= {path, ty}, instTyList} =>
      T.OVERLOAD_EXVAR {exVarInfo= {path=path, ty=substTy (subst,ty)}, 
                        instTyList=map (fn ty=> substTy(subst,ty)) instTyList}
    | T.OVERLOAD_PRIM {primInfo={primitive, ty}, instTyList} =>
      T.OVERLOAD_PRIM {primInfo={primitive=primitive, ty=substTy(subst,ty)}, 
                       instTyList=map (fn ty=> substTy(subst,ty)) instTyList}
    | T.OVERLOAD_CASE (ty, overloadMatchTypIdMap) =>
      T.OVERLOAD_CASE (substTy(subst, ty), 
                       TypID.Map.map (fn match => substMatch(subst,match)) overloadMatchTypIdMap)
  and substInstMap (subst,instMap) = OPrimInstMap.map (fn match=> substMatch(subst,match)) instMap

  fun reduceTyCon (tyCon as {id, path, iseq, arity, runtimeTy, conSet, extraArgs, dtyKind}) =
      case dtyKind of
        T.DTY => tyCon
      | T.BUILTIN _ => tyCon
      | T.OPAQUE {opaqueRep, revealKey} =>
        (case opaqueRep of
           T.TYCON tyCon  => reduceTyCon tyCon
         | T.TFUNDEF _ => tyCon)



  fun reduceTy ty =
      case TypesUtils.derefTy ty of
      T.SINGLETONty singletonTy => T.SINGLETONty (reduceSingletonTy singletonTy)
    | T.ERRORty => ty
    | T.DUMMYty dummyTyID => ty
    | T.TYVARty tvStateRef => ty
    | T.BOUNDVARty id => ty
    | T.FUNMty (tylist, ty) => T.FUNMty (map reduceTy tylist, reduceTy ty)
    | T.RECORDty tymap => T.RECORDty (LabelEnv.map reduceTy tymap)
    | T.CONSTRUCTty {tyCon as {arity,dtyKind,...}, args} =>
      let
        val args = map reduceTy args
        val tyCon as {dtyKind, ...} = reduceTyCon tyCon
      in
        case dtyKind of
          T.DTY => T.CONSTRUCTty {tyCon=tyCon, args=args}
        | T.BUILTIN _ => T.CONSTRUCTty {tyCon=tyCon, args=args}
        | T.OPAQUE {opaqueRep, revealKey} =>
          (case opaqueRep of
             T.TYCON tyCon => T.CONSTRUCTty {tyCon=tyCon, args=args}
           | T.TFUNDEF {polyTy=T.POLYty {boundtvars, body}, ...} =>
             let
               val btvTyList = ListPair.zip (BoundTypeVarID.Map.listKeys boundtvars, args)
               val subst = foldr
                             (fn ((id,ty), subst) => 
                                 BoundTypeVarID.Map.insert(subst, id, ty))
                             BoundTypeVarID.Map.empty
                             btvTyList
             in
               substTy(subst,body)
             end
           | _ => raise (Control.Bug ("ReduceTy: " ^ "non polyty in TFUNDEF"))
          )
      end
    | T.POLYty {boundtvars, body} => T.POLYty {boundtvars=boundtvars, body=reduceTy body}
  and reduceSingletonTy ty =
      case ty of
      T.INSTCODEty oprimSelector => T.INSTCODEty (reduceOprimSelector oprimSelector)
    | T.INDEXty (string, ty) => T.INDEXty (string, reduceTy ty)
    | T.TAGty ty => T.TAGty (reduceTy ty)
    | T.SIZEty ty => T.SIZEty (reduceTy ty)
  and reduceOprimSelector {oprimId, path, keyTyList, match, instMap} =
      {oprimId=oprimId, 
       path=path, 
       keyTyList=map reduceTy keyTyList, 
       match = reduceMatch match, 
       instMap = reduceInstMap instMap}
  and reduceMatch match =
      case match of
      T.OVERLOAD_EXVAR {exVarInfo= {path, ty}, instTyList} =>
      T.OVERLOAD_EXVAR {exVarInfo= {path=path, ty=reduceTy ty}, 
                        instTyList=map reduceTy instTyList}
    | T.OVERLOAD_PRIM {primInfo={primitive, ty}, instTyList} =>
      T.OVERLOAD_PRIM {primInfo={primitive=primitive, ty=reduceTy ty}, 
                       instTyList=map reduceTy instTyList}
    | T.OVERLOAD_CASE (ty, overloadMatchTypIdMap) =>
      T.OVERLOAD_CASE (reduceTy ty, 
                       TypID.Map.map reduceMatch overloadMatchTypIdMap)
  and reduceInstMap instMap = OPrimInstMap.map reduceMatch instMap
end
