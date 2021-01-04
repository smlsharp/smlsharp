structure IntIntStringOrd =
struct
  type ord_key = int * int * string
  fun compare ((i11,i12, s1), (i21, i22, s2)) =
      case Int.compare(i11, i21) of
        EQUAL => (case Int.compare(i12, i22) of
                    EQUAL => String.compare(s1,s2)
                  | x => x)
      | x => x
end

structure IntIntStringMap = BinaryMapFn(IntIntStringOrd)
structure IntIntStringSet = BinarySetFn(IntIntStringOrd)
