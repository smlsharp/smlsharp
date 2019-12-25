open SMLUnit.Test SMLUnit.Assert

val _ = assertTrue (d1 = D1)
val _ = assertTrue (D21 1 <> D22 "A")
val _ = assertTrue (D21 1 <> D22 "A")
val _ = assertTrue (D31 D322 <> D31 (D321 (D31 D322)))
val _ = assertTrue (D4 1 <> D4 2)
val _ = assertTrue ((1 D5 2) <>  (1 D5 3))
