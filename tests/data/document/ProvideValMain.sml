open SMLUnit.Test SMLUnit.Assert
val _ = assertEqualInt 1 i
val _ = assertTrue (0x7F = i8)
val _ = assertTrue (0x7FFF = i16)
val _ = assertTrue (0x7FFFFFFF = i32)
val _ = assertTrue (0x7FFFFFFFFFFFFFFF = i64)

val _ = assertEqualWord 0w1 w
val _ = assertTrue (0wxFF = w8)
val _ = assertTrue (0wxFFFF = w16)
val _ = assertTrue (0wxFFFFFFFF = w32)
val _ = assertTrue (0wxFFFFFFFFFFFFFFFF = w64)

val _ = assertTrue (Real.==  (0.1, r))
val _ = assertTrue (Real32.==  (0.2, r32))
val _ = assertTrue (#"A" = c)
val _ = assertEqualString "ABC" s
val _ = assertTrue b

val _ = assertEqualInt 2 (!ref1)
val _ = assertTrue ((1, "A") = tuple1)
val _ = assertTrue ((2, "B") = tuple2)
val _ = assertTrue ({A=1, B="A"} = record1)
val _ = assertEqualIntList [1, 2, 3] list1

val _ = assertEqualInt 1 (f1 1)
val _ = assertEqualString "A" (f1 "A")
val _ = assertEqualInt 2 (f2 1)
val _ = assertEqualWord 0w2 (f3 0w1)
val _ = assertEqualWord 0w2 (f4 0w1)
val _ = assertEqualInt 1 (f5 1)
val _ = (f6 1; fail "NG f6 1") handle _ => 0w1
val _ = (f6 "A"; fail "NG f6 A") handle _ => #"B"
val _ = assertEqualString "A" v1
