(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)
structure CompareTy =
struct
  open Types
  fun compareList comp (h1::t1, h2::t2) =
      (case comp (h1,h2) of
         EQUAL => compareList comp (t1,t2) 
      | res => res)
    | compareList comp (nil, nil) = EQUAL
    | compareList comp (h::_, _) =  GREATER
    | compareList comp (_, h::_) =  LESS 
  fun comparePair compFst compSnd ((x1,y1), (x2, y2)) = 
      case compFst (x1, x2) of
        EQUAL => compSnd (y1, y2)
      | res => res
  fun tyTag ty =
      case ty of
        SINGLETONty _ => 0
      | BACKENDty _ => 1
      | ERRORty => 2
      | DUMMYty  _ => 3
      | EXISTty  _ => 4
      | TYVARty (ref (SUBSTITUTED ty)) => tyTag ty
      | TYVARty  _ => 5
      | BOUNDVARty  _ => 6
      | FUNMty  _ => 7
      | RECORDty  _ => 8
      | CONSTRUCTty  _ => 9
      | POLYty  _ => 10
  fun singletonTyTag sty =
      case sty of
      INSTCODEty _ => 0
    | INDEXty _ => 1
    | TAGty _ => 2
    | SIZEty _ => 3
    | REIFYty  _ => 4
  fun compareSingletonTy (s1, s2) =
    if singletonTyTag s1 <> singletonTyTag s2 then 
      Int.compare (singletonTyTag s1, singletonTyTag s2)
    else 
      case (s1, s2) of
        (INSTCODEty {oprimId=id1, ...}, INSTCODEty {oprimId=id2, ...}) =>
        OPrimID.compare (id1, id2)
      | (INDEXty x, INDEXty y) => 
        comparePair 
          (fn (x,y) => String.compare(RecordLabel.toString x, RecordLabel.toString y))
          compareTy  (x,y)
      | (TAGty ty1, TAGty ty2) => compareTy (ty1, ty2)
      | (SIZEty ty1, SIZEty ty2) => compareTy (ty1, ty2)
      | (REIFYty ty1, REIFYty ty2) => compareTy (ty1, ty2)
      | _ => raise Bug.Bug "impossible"
  and compareField ((l1,ty1), (l2,ty2)) =
      case String.compare(RecordLabel.toString l1, RecordLabel.toString l2) of
        EQUAL => compareTy (ty1, ty2)
      | res => res
  and compareTyMap (map1, map2) = RecordLabel.Map.collate compareTy (map1, map2)
  and compareTy (ty1, ty2) =
      if tyTag ty1 <> tyTag ty2 then Int.compare (tyTag ty1, tyTag ty2)
      else 
        case (ty1, ty2) of
          (TYVARty (ref (SUBSTITUTED ty1)), _ ) => compareTy (ty1, ty2)
        | (_, TYVARty (ref (SUBSTITUTED ty2))) => compareTy (ty1, ty2)
        | (TYVARty (ref (TVAR {id=id1, ...})), TYVARty (ref (TVAR {id=id2,...}))) => 
          FreeTypeVarID.compare (id1, id2)
        | (BOUNDVARty id1, BOUNDVARty id2) => BoundTypeVarID.Map.Key.compare(id1, id2)
        | (FUNMty (tyList1, ty1),FUNMty (tyList2, ty2)) => 
          compareList compareTy (ty1::tyList1, ty2::tyList2)
        | (RECORDty tyMap1, RECORDty tyMap2) => compareTyMap (tyMap1, tyMap2)
        | (CONSTRUCTty {tyCon={id=id1,...}, args=args1,...},
           CONSTRUCTty {tyCon={id=id2,...}, args=args2,...}) =>
          comparePair TypID.Map.Key.compare (compareList compareTy) ((id1,args1), (id2,args2))
        | (EXISTty (id1, _), EXISTty (id2, _)) =>
          ExistTyID.compare (id1, id2)
        | _ => raise Bug.Bug "impossible"
end
