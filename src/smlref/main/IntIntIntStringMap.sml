structure IntIntIntStringOrd =
struct
  type ord_key = int * int * int * string
  fun compare ((i11,i12, i13, s1), (i21, i22, i23, s2)) =
      case Int.compare(i11, i21) of
        EQUAL => (case Int.compare(i12, i22) of
                    EQUAL => 
                     (case Int.compare (i13, i23) of
                        EQUAL => String.compare(s1,s2)
                      | x => x)
                  | x => x)
      | x => x
end

structure IntIntIntStringMap = BinaryMapFn(IntIntIntStringOrd)
structure IntIntIntStringSet = BinarySetFn(IntIntIntStringOrd)
