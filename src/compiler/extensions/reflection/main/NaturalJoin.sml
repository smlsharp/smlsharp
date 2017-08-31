(**
 * NaturalJoin
 * @copyright (c) 2017- Tohoku University.
 * @author Tomohiro Sasaki
 *)

structure NaturalJoin =
struct
  structure R = ReifiedTerm

  exception NaturalJoin
  exception NaturalJoinTypeNotMatch of R.reifiedTerm * R.reifiedTerm
  exception UnsupportedTerm of R.reifiedTerm * R.reifiedTerm

  fun naturalJoin (x, y) =
      case (x, y) of
        (R.ARRAY _, R.ARRAY _) =>
        raise UnsupportedTerm (x, y)
      | (R.ARRAY2 arr1, R.ARRAY2 arr2) =>
        (* nested-loop join *)
        let
          val joinedRev =
              Array.foldl (fn (rt1, joinedRev) =>
                              Array.foldl (fn (rt2, joinedRev) =>
                                              naturalJoin (rt1, rt2) :: joinedRev
                                              handle NaturalJoin => joinedRev)
                                          joinedRev
                                          arr2)
                          nil
                          arr1
        in
          R.ARRAY2 (Array.fromList (List.rev joinedRev))
        end
      | (R.BOOL b1, R.BOOL b2) =>
        if b1 = b2 then x else raise NaturalJoin
      | (R.BOUNDVAR, R.BOUNDVAR) =>
        raise UnsupportedTerm (x, y)
      | (R.CHAR c1, R.CHAR c2) =>
        if c1 = c2 then x else raise NaturalJoin
      | (R.CODEPTR _, R.CODEPTR _) =>
        raise UnsupportedTerm (x, y)
      | (R.DATATYPE (con1, termOpt1), R.DATATYPE (con2, termOpt2)) =>
        if con1 = con2 
        then (case (termOpt1, termOpt2) of
                (SOME term1, SOME term2) => 
                R.DATATYPE (con1, SOME (naturalJoin (term1, term2)))
              | (NONE, NONE) =>
                R.DATATYPE (con1, NONE)
              | _ => raise UnsupportedTerm (x, y))
        else raise NaturalJoin
      | (R.EXNTAG, R.EXNTAG) =>
        raise UnsupportedTerm (x, y)
      | (R.EXN _, R.EXN _) =>
        raise UnsupportedTerm (x, y)
      | (R.INT i1, R.INT i2) =>
        if i1 = i2 then x else raise NaturalJoin
      | (R.INT8 i1, R.INT8 i2) =>
        if i1 = i2 then x else raise NaturalJoin
      | (R.INT16 i1, R.INT16 i2) =>
        if i1 = i2 then x else raise NaturalJoin
      | (R.INT64 i1, R.INT64 i2) =>
        if i1 = i2 then x else raise NaturalJoin
      | (R.INTERNAL, R.INTERNAL) =>
        raise UnsupportedTerm (x, y)
      | (R.INTINF i1, R.INTINF i2) =>
        if i1 = i2 then x else raise NaturalJoin
      | (R.LIST l1, R.LIST l2) =>
        (* nested-loop join *)
        let
          val joinedRev =
              List.foldl (fn (rt1, joinedRev) =>
                             List.foldl (fn (rt2, joinedRev) =>
                                            naturalJoin (rt1, rt2) :: joinedRev
                                            handle NaturalJoin => joinedRev)
                                        joinedRev
                                        l2)
                         nil
                         l1
        in
          R.LIST (List.rev joinedRev)
        end
      | (R.OPAQUE, R.OPAQUE) =>
        raise UnsupportedTerm (x, y)
      | (R.OPTION (SOME op1), R.OPTION (SOME op2)) =>
        R.OPTION (SOME (naturalJoin (op1, op2)))
      | (R.OPTION (SOME op1), R.OPTION NONE) => x
      | (R.OPTION NONE, R.OPTION (SOME op2)) => y
      | (R.OPTION NONE, R.OPTION NONE) => x
      | (R.OPTIONSOME op1, R.OPTIONSOME op2) =>
        R.OPTIONSOME (naturalJoin (op1, op2))
      | (R.OPTIONSOME op1, R.OPTIONNONE) => x
      | (R.OPTIONNONE, R.OPTIONSOME op2) => y
      | (R.OPTIONNONE, R.OPTIONNONE) => x
      | (R.OPTIONNONE, _) =>
        naturalJoin (R.OPTION NONE, y)
      | (_, R.OPTIONNONE) =>
        naturalJoin (x, R.OPTION NONE)
      | (R.OPTIONSOME op1, _) =>
        naturalJoin (R.OPTION (SOME op1), y)
      | (_, R.OPTIONSOME op2) =>
        naturalJoin (x, R.OPTION (SOME op2))
      | (R.POLY _, R.POLY _) =>
        raise UnsupportedTerm (x, y)
      | (R.PTR p1, R.PTR p2) =>
        if p1 = p2 then x else raise NaturalJoin
      | (R.REAL32 r1, R.REAL32 r2) =>
        if Real32.== (r1, r2) then x else raise NaturalJoin
      | (R.REAL r1, R.REAL r2) =>
        if Real.== (r1, r2) then x else raise NaturalJoin
      | (R.RECORD r1, R.RECORD r2) =>
        (* sort-merge join *)
        let
          fun merge (nil, nil) = nil
            | merge (rec1, nil) = rec1
            | merge (nil, rec2) = rec2
            | merge (rec1 as ((l1, rt1) :: rest1), 
                     rec2 as ((l2, rt2) :: rest2)) =
              if l1 < l2 then (l1, rt1) :: merge (rest1, rec2)
              else if l1 > l2 then (l2, rt2) :: merge (rec1, rest2)
              else (l1, naturalJoin (rt1, rt2)) :: merge (rest1, rest2)
        in
          R.RECORD (merge (r1, r2))
        end
      | (R.REF r1, R.REF r2) =>
        R.REF (naturalJoin (r1, r2))
      | (R.STRING s1, R.STRING s2) =>
        if s1 = s2 then x else raise NaturalJoin
      | (R.TUPLE t1, R.TUPLE t2) =>
        (* sort-merge join *)
        let
          fun merge (nil, nil) = nil
            | merge (t1, nil) = t1
            | merge (nil, t2) = t2
            | merge (rt1 :: rest1, rt2 :: rest2) =
              naturalJoin (rt1, rt2) :: merge (rest1, rest2)
        in
          R.TUPLE (merge (t1, t2))
        end
      | (R.UNIT, R.UNIT) => x
      | (R.VECTOR _, R.VECTOR _) =>
        raise UnsupportedTerm (x, y)
      | (R.VECTOR2 vec1, R.VECTOR2 vec2) =>
        (* nested-loop join *)
        let
          val joinedRev =
              Vector.foldl (fn (rt1, joinedRev) =>
                               Vector.foldl (fn (rt2, joinedRev) =>
                                                naturalJoin (rt1, rt2) :: joinedRev
                                                handle NaturalJoin => joinedRev)
                                            joinedRev
                                            vec2)
                           nil
                           vec1
        in
          R.VECTOR2 (Vector.fromList (List.rev joinedRev))
        end
      | (R.WORD w1, R.WORD w2) =>
        if w1 = w2 then x else raise NaturalJoin
      | (R.WORD8 w1, R.WORD8 w2) =>
        if w1 = w2 then x else raise NaturalJoin
      | (R.WORD16 w1, R.WORD16 w2) =>
        if w1 = w2 then x else raise NaturalJoin
      | (R.WORD64 w1, R.WORD64 w2) =>
        if w1 = w2 then x else raise NaturalJoin
      | (R.BUILTIN, R.BUILTIN) =>
        raise UnsupportedTerm (x, y)
      | (R.ELIPSIS, R.ELIPSIS) =>
        raise UnsupportedTerm (x, y)
      | (R.FUN {closure=f1,...}, R.FUN {closure=f2,...}) =>
        if SMLSharp_Builtin.Pointer.identityEqual (f1, f2) 
        then x else raise NaturalJoin
      | (R.UNPRINTABLE, R.UNPRINTABLE) =>
        raise UnsupportedTerm (x, y)
      | _ => raise NaturalJoinTypeNotMatch (x, y)
end
