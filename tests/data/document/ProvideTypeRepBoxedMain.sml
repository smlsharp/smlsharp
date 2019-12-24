open SMLUnit.Test SMLUnit.Assert


val _ = r1 : r1
val _ = r2 : (int, string) r2
val _ = assertTrue (r31 <> r32)

val _ = a1 : a1
val _ = a2 : int a2
val _ = assertTrue (a31 <> a32)

val _ = f1 : f1
val _ = f2 : ('a, 'b) f2
val _ = assertEqualInt 1 (f3 f1 1)

val _ = d11 : d1
val _ = d12 : d1
val _ = d21 : (int, 'a) d2
val _ = d22 : ('a, string) d2
val _ = assertTrue (d31 <> d321)
val _ = assertTrue (d31 <> d322)
