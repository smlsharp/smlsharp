(**
 * NaturalJoin
 * @copyright (c) 2017-2018 Tohoku University.
 * @author Tomohiro Sasaki
 * @author Atsushi Ohori
 *)

structure NaturalJoin =
struct
  structure BP = SMLSharp_Builtin.Pointer
  structure RTm = ReifiedTerm
  structure RTy = ReifiedTy
  structure PD = PartialDynamic
  exception NaturalJoin
  exception Extend
  exception GreaterEq
  exception UnsupportedTerm of RTm.reifiedTerm * RTm.reifiedTerm
  datatype joinKind = JOIN | EXTEND 

  fun joinBoxed joinKind (b1,b2) = 
      case joinKind of 
        JOIN => if BP.identityEqual (b1, b2) then b1 else raise NaturalJoin
      | EXTEND => b2

  fun joinEq joinKind (v1,v2) = 
      case joinKind of 
        JOIN => if v1 = v2 then v1 else raise NaturalJoin
      | EXTEND => v2

  fun joinRealEq joinKind (v1,v2) = 
      case joinKind of 
        JOIN => if Real.==(v1,v2) then v1 else raise NaturalJoin
      | EXTEND => v2

  fun nullExtend (term, ty) = 
      let
        val termTy = PD.inferTy term
      in
        if RTy.reifiedTyEq (termTy, ty) then term
        else 
          case (term, ty) of
            (RTm.RECORD fields, RTy.RECORDty tyFields) =>
            RTm.RECORD (RecordLabel.Map.mergeWith
                          (fn (SOME v, SOME ty) => SOME (nullExtend (v,ty))
                            | (NONE, SOME ty) =>  SOME (PD.genNull ty)
                            | (SOME v, NONE) => SOME v
                            | (NONE, NONE) => NONE)
                          (fields, tyFields))
          | (RTm.LIST l, RTy.LISTty ty) => 
            RTm.LIST (map (fn term => nullExtend(term, ty)) l)
          | _ => raise NaturalJoin
      end

  fun nullOverride (term, ty) = 
      let
        val termTy = PD.inferTy term
      in
        if RTy.reifiedTyEq (termTy, ty) then PD.genNull ty
        else 
          case (term, ty) of
            (RTm.RECORD fields, RTy.RECORDty tyFields) =>
            RTm.RECORD (RecordLabel.Map.mergeWith
                          (fn (SOME v, SOME ty) => SOME (nullOverride (v,ty))
                            | (NONE, SOME ty) =>  SOME (PD.genNull ty)
                            | (SOME v, NONE) => SOME v
                            | (NONE, NONE) => NONE)
                          (fields, tyFields))
          | (RTm.LIST l, RTy.LISTty ty) => 
            RTm.LIST (map (fn term => nullOverride(term, ty)) l)
          | _ => raise NaturalJoin (* impossible *)
      end

  fun joinList joinKind (l1, l2) =
      case joinKind of
        JOIN => 
        List.rev 
          (List.foldl
             (fn (rt1, joinedRev) =>
                 List.foldl (fn (rt2, joinedRev) =>
                                naturalJoin joinKind (rt1, rt2) :: joinedRev
                                handle NaturalJoin => joinedRev)
                            joinedRev
                            l2)
             nil
             l1)
      | EXTEND => l2

  and joinFields joinKind (map1, map2) =
      RecordLabel.Map.mergeWith
      (fn (SOME v1, SOME v2) => SOME (naturalJoin joinKind (v1,v2))
        | (NONE, SOME v) => SOME v
        | (SOME v, NONE) => SOME v
        | (NONE, NONE) => NONE)
      (map1, map2)

  and joinData joinKind ((con1, termOpt1, ty1), (con2, termOpt2, ty2)) =
      if con1 = con2 
      then 
        case (termOpt1, termOpt2) of
          (SOME term1, SOME term2) => 
          (con1, SOME (naturalJoin joinKind (term1, term2)), ty1)
        | (NONE, NONE) =>  (con1, NONE, ty1)
        | _ => raise Bug.Bug "Natural join on datatype"
      else raise NaturalJoin

  and joinDynamic joinKind ((ty1, boxed1), (ty2, boxed2)) = 
      let
        val term1 = BP.castFromBoxed boxed1 : RTm.reifiedTerm
        val term2 = BP.castFromBoxed boxed2 : RTm.reifiedTerm
        val ty = PD.lubTy (ty1, ty2)
      in
        (ty, BP.castToBoxed (RTm.toDynamic (naturalJoin joinKind (term1, term2))))
      end

  and joinOption joinKind ((o1, ty1), (o2, ty2)) =
      let
        val ty = PD.lubTy (ty1, ty2)
        val opt = 
            case (o1, o2) of
              (SOME v1, SOME v2) => SOME (naturalJoin joinKind (v1, v2))
            | (NONE, NONE) =>  NONE
            | _ => (case joinKind of JOIN => raise NaturalJoin | EXTEND => o2)
      in
        (opt, ty)
      end

  and naturalJoin joinKind (x, y) =
      case (x, y) of
        (RTm.NULL, _) => y
      | (_, RTm.NULL) => x
      | (RTm.NULL_WITHTy ty1, _) => nullExtend (y, ty1)
      | (_, RTm.NULL_WITHTy ty2) => 
        (case joinKind of 
           JOIN => nullExtend (x, ty2)
         | EXTEND => nullOverride (x, ty2)
        )
      | (RTm.ARRAY (ty1, b1), RTm.ARRAY (ty2, b2)) => RTm.ARRAY (ty1, joinBoxed joinKind (b1,b2))
      | (RTm.BOOL b1, RTm.BOOL b2) => RTm.BOOL (joinEq joinKind (b1,b2))
      | (RTm.CHAR c1, RTm.CHAR c2) => RTm.CHAR (joinEq joinKind (c1,c2))
      | (RTm.DATATYPE d1, RTm.DATATYPE d2) => RTm.DATATYPE (joinData joinKind (d1,d2))
      | (RTm.DYNAMIC d1, RTm.DYNAMIC d2) => RTm.DYNAMIC (joinDynamic joinKind (d1,d2))
      | (RTm.INT32 i1, RTm.INT32 i2) => RTm.INT32 (joinEq joinKind (i1, i2))
      | (RTm.INT8 i1, RTm.INT8 i2) => RTm.INT8 (joinEq joinKind (i1,i2))
      | (RTm.INT16 i1, RTm.INT16 i2) => RTm.INT16 (joinEq joinKind (i1,i2))
      | (RTm.INT64 i1, RTm.INT64 i2) => RTm.INT64 (joinEq joinKind (i1,i2))
      | (RTm.INTINF i1, RTm.INTINF i2) => RTm.INTINF (joinEq joinKind (i1,i2))
      | (RTm.LIST l1, RTm.LIST l2) => RTm.LIST (joinList joinKind (l1,l2))
      | (RTm.OPTION opt1, RTm.OPTION opt2) => RTm.OPTION  (joinOption joinKind (opt1, opt2))
      | (RTm.PTR p1, RTm.PTR p2) => RTm.PTR (joinEq joinKind (p1,p2))
      | (RTm.REAL32 r1, RTm.REAL32 r2) =>
        (case joinKind of
           JOIN => if Real32.== (r1, r2) then x else raise NaturalJoin
         | EXTEND =>  y)
      | (RTm.REAL64 r1, RTm.REAL64 r2) =>  
        (case joinKind of
           JOIN => if Real64.== (r1, r2) then x else raise NaturalJoin
         | EXTEND =>  y)
      | (RTm.RECORD r1, RTm.RECORD r2) => RTm.RECORD (joinFields joinKind (r1,r2))
      | (RTm.REF (ty1, b1), RTm.REF (ty2, b2)) => RTm.REF (ty1, joinBoxed joinKind (b1,b2))
      | (RTm.STRING s1, RTm.STRING s2) => RTm.STRING (joinEq joinKind (s1,s2))
      | (RTm.UNIT, RTm.UNIT) => x
      | (RTm.VECTOR_PRINT vec1, RTm.VECTOR_PRINT vec2) => raise NaturalJoin
      | (RTm.VECTOR (ty1, b1), RTm.VECTOR (ty2, b2)) => RTm.VECTOR (ty1, joinBoxed joinKind (b1,b2))
      | (RTm.WORD32 w1, RTm.WORD32 w2) => RTm.WORD32 (joinEq joinKind (w1,w2))
      | (RTm.WORD8 w1, RTm.WORD8 w2) => RTm.WORD8 (joinEq joinKind (w1,w2))
      | (RTm.WORD16 w1, RTm.WORD16 w2) => RTm.WORD16 (joinEq joinKind (w1,w2))
      | (RTm.WORD64 w1, RTm.WORD64 w2) => RTm.WORD64 (joinEq joinKind (w1,w2))
      | (RTm.FUN {closure=b1,ty=ty1}, RTm.FUN {closure=b2,ty=ty2}) => 
        RTm.FUN {closure=joinBoxed joinKind (b1,b2),ty=ty1}
      | (RTm.ARRAY_PRINT _, _) => raise UnsupportedTerm (x, y)
      | (RTm.BOUNDVAR, _) => raise UnsupportedTerm (x, y)
      | (RTm.BUILTIN, _) => raise UnsupportedTerm (x, y)
      | (RTm.CODEPTR _, _) => raise UnsupportedTerm (x, y)
      | (RTm.EXNTAG, _) => raise UnsupportedTerm (x, y)
      | (RTm.EXN _, _) => raise UnsupportedTerm (x, y)
      | (RTm.INTERNAL, _) => raise UnsupportedTerm (x, y)
      | (RTm.OPAQUE, _) => raise UnsupportedTerm (x, y)
      | (RTm.REF_PRINT _, _) => raise UnsupportedTerm (x, y)
      | (RTm.UNPRINTABLE, _) => raise UnsupportedTerm (x, y)
      | (_, RTm.ARRAY_PRINT _) => raise UnsupportedTerm (x, y)
      | (_, RTm.BOUNDVAR) => raise UnsupportedTerm (x, y)
      | (_, RTm.BUILTIN) => raise UnsupportedTerm (x, y)
      | (_, RTm.CODEPTR _) => raise UnsupportedTerm (x, y)
      | (_, RTm.EXNTAG) => raise UnsupportedTerm (x, y)
      | (_, RTm.EXN _) => raise UnsupportedTerm (x, y)
      | (_, RTm.INTERNAL) => raise UnsupportedTerm (x, y)
      | (_, RTm.OPAQUE) => raise UnsupportedTerm (x, y)
      | (_, RTm.REF_PRINT _) => raise UnsupportedTerm (x, y)
      | (_, RTm.UNPRINTABLE) => raise UnsupportedTerm (x, y)
      | _ => raise NaturalJoin

  val naturalJoin = fn x => naturalJoin JOIN x

  fun overrideNull (term, ty) = 
      if RTy.reifiedTyEq (PD.inferTy term, ty) then RTm.NULL_WITHTy ty
      else 
        case (term, ty) of
          (RTm.RECORD fields, RTy.RECORDty tyFields) =>
          RTm.RECORD (RecordLabel.Map.mergeWith
                        (fn (SOME v, SOME ty) => SOME (overrideNull (v, ty))
                          | (SOME v, NONE) => SOME v
                          | (NONE, SOME ty) => NONE
                          | (NONE, NONE) => NONE)
                        (fields, tyFields))
        | _ => term
  and overrideValue (ty, term) = 
      if RTy.reifiedTyEq (PD.inferTy term, ty) then term
      else 
        case (ty, term) of
          (RTy.RECORDty tyFields, RTm.RECORD fields) =>
          RTm.RECORD (RecordLabel.Map.mergeWith
                        (fn (SOME ty, SOME v) => SOME (overrideValue (ty, v))
                          | (SOME ty, NONE) => SOME (RTm.NULL_WITHTy ty)
                          | (NONE, SOME v) => NONE
                          | (NONE, NONE) => NONE)
                        (tyFields, fields))
        | _ => RTm.NULL_WITHTy ty
  and overrideFields (map1, map2) =
      RecordLabel.Map.mergeWith
      (fn (SOME v1, SOME v2) => SOME (override (v1, v2))
        | (SOME v, NONE) => SOME v
        | (NONE, SOME v) => NONE
        | (NONE, NONE) => NONE)
      (map1, map2)
  and override (x, y) =
      case (x, y) of
        (RTm.RECORD r1, RTm.RECORD r2) => RTm.RECORD (overrideFields (r1, r2))
      | (RTm.NULL_WITHTy ty1, _) => overrideValue (ty1, y)
      | (_, RTm.NULL_WITHTy ty2) => overrideNull (x, ty2)
      | _ => y
  and extendFields (map1, map2) =
      RecordLabel.Map.mergeWith
      (fn (SOME v1, SOME v2) => SOME (extend (v1, v2))
        | (NONE, SOME v) => SOME v
        | (SOME v, NONE) => SOME v
        | _ => raise Extend)
      (map1, map2)
  and extend (x,y) = 
      case (x, y) of
        (RTm.RECORD r1, RTm.RECORD r2) => RTm.RECORD (extendFields (r1, r2))
      | _ => raise Extend

  fun greaterEqData ((con1, termOpt1, ty1), (con2, termOpt2, ty2)) =
      con1 = con2 
      andalso 
      case (termOpt1, termOpt2) of
        (SOME term1, SOME term2) => greaterEq (term1, term2)
      | (NONE, NONE) =>  true
      | _ => false

  and greaterEqFields (map1, map2) =
      let
        exception Fail
      in
        (RecordLabel.Map.mergeWith
           (fn (SOME v1, SOME v2) => if greaterEq (v1,v2) then NONE else raise Fail
             | (NONE, SOME v) => raise Fail
             | _ => NONE)
           (map1, map2);
         true)
        handle Fail => false
      end

  and greaterEqList (l1, l2) =
      let
        fun greaterEqListSome (x,L) = List.exists (fn y => greaterEq(x,y)) L
      in
        List.all (fn x => greaterEqListSome(x,l2)) l1
      end

  and greaterEqOption ((opt1, ty1), (opt2, ty2)) = 
      case (opt1,opt2) of
        (NONE,NONE) => true
      | (SOME term1, SOME term2) => greaterEq (term1, term2)
      | _ => false

  and greaterEqDynamic ((ty1, boxed1), (ty2, boxed2)) = 
      let
        val term1 = BP.castFromBoxed boxed1 : RTm.reifiedTerm
        val term2 = BP.castFromBoxed boxed2 : RTm.reifiedTerm
      in
        greaterEq (term1, term2)
      end

  and greaterEq (x, y) =
      case (x, y) of
        (_, RTm.NULL) => true
      | (_, RTm.NULL_WITHTy ty1) => PD.matchTy (PD.inferTy x, ty1)
      | (RTm.VOID, RTm.VOID) => true
      | (RTm.VOID_WITHTy ty1, RTm.VOID_WITHTy ty2) => PD.matchTy(ty1, ty2)
      | (RTm.ARRAY (ty1, b1), RTm.ARRAY (ty2, b2)) => BP.identityEqual (b1, b2)
      | (RTm.ARRAY_PRINT _, _) => raise UnsupportedTerm (x, y)
      | (RTm.BOOL b1, RTm.BOOL b2) => b1 = b2
      | (RTm.BOUNDVAR, _) => raise UnsupportedTerm (x, y)
      | (RTm.BUILTIN, _) => raise UnsupportedTerm (x, y)
      | (RTm.CHAR c1, RTm.CHAR c2) => c1 = c2
      | (RTm.CODEPTR w1, RTm.CODEPTR w2) => w1 = w2
      | (RTm.DATATYPE d1, RTm.DATATYPE d2) => greaterEqData (d1,d2)
      | (RTm.DYNAMIC d1, RTm.DYNAMIC d2) => greaterEqDynamic (d1,d2)
      | (RTm.EXN _, _) => raise UnsupportedTerm (x, y)
      | (RTm.EXNTAG, _) => raise UnsupportedTerm (x, y)
      | (RTm.FUN {closure=b1,ty=ty1}, RTm.FUN {closure=b2,ty=ty2}) => BP.identityEqual (b1, b2)
      | (RTm.INT32 i1, RTm.INT32 i2) => i1 = i2
      | (RTm.INT16 i1, RTm.INT16 i2) => i1 = i2
      | (RTm.INT64 i1, RTm.INT64 i2) => i1 = i2
      | (RTm.INT8 i1, RTm.INT8 i2) => i1 = i2
      | (RTm.INTERNAL, _) => raise UnsupportedTerm (x, y)
      | (RTm.INTINF i1, RTm.INTINF i2) => i1 = i2
      | (RTm.LIST l1, RTm.LIST l2) => greaterEqList (l1,l2)
      | (RTm.OPAQUE, _) => raise UnsupportedTerm (x, y)
      | (RTm.OPTION opt1, RTm.OPTION opt2) => greaterEqOption (opt1, opt2)
      | (RTm.PTR p1, RTm.PTR p2) => p1 = p2
      | (RTm.REAL64 r1, RTm.REAL64 r2) =>  Real64.== (r1, r2)
      | (RTm.REAL32 r1, RTm.REAL32 r2) => Real32.== (r1, r2)
      | (RTm.RECORD r1, RTm.RECORD r2) => greaterEqFields (r1,r2)
      | (RTm.REF (ty1, b1), RTm.REF (ty2, b2)) => BP.identityEqual (b1, b2)
      | (RTm.REF_PRINT _, _) => raise UnsupportedTerm (x, y)
      | (RTm.STRING s1, RTm.STRING s2) => s1 = s2
      | (RTm.UNIT, RTm.UNIT) => true
      | (RTm.UNPRINTABLE, _) => raise UnsupportedTerm (x, y)
      | (RTm.VECTOR (ty1, b1), RTm.VECTOR (ty2, b2)) => BP.identityEqual (b1, b2)
      | (RTm.VECTOR_PRINT vec1, RTm.VECTOR_PRINT vec2) => raise GreaterEq
      | (RTm.WORD32 w1, RTm.WORD32 w2) => w1 = w2
      | (RTm.WORD16 w1, RTm.WORD16 w2) =>  w1 = w2
      | (RTm.WORD64 w1, RTm.WORD64 w2) =>  w1 = w2
      | (RTm.WORD8 w1, RTm.WORD8 w2) =>  w1 = w2
      | (_, RTm.ARRAY_PRINT _) => raise UnsupportedTerm (x, y)
      | (_, RTm.BOUNDVAR) => raise UnsupportedTerm (x, y)
      | (_, RTm.BUILTIN) => raise UnsupportedTerm (x, y)
      | (_, RTm.CODEPTR _) => raise UnsupportedTerm (x, y)
      | (_, RTm.EXNTAG) => raise UnsupportedTerm (x, y)
      | (_, RTm.EXN _) => raise UnsupportedTerm (x, y)
      | (_, RTm.INTERNAL) => raise UnsupportedTerm (x, y)
      | (_, RTm.OPAQUE) => raise UnsupportedTerm (x, y)
      | (_, RTm.REF_PRINT _) => raise UnsupportedTerm (x, y)
      | (_, RTm.UNPRINTABLE) => raise UnsupportedTerm (x, y)
      | _ => false

end
