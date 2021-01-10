structure IntStringOrd =
struct
  type ord_key = int * string
  fun compare ((i1,s1), (i2, s2)) =
      case Int.compare(i1, i2) of
        EQUAL => String.compare(s1,s2)
      | x => x
end

structure IntStringMap = BinaryMapFn(IntStringOrd)
structure IntStringSet = BinarySetFn(IntStringOrd)
