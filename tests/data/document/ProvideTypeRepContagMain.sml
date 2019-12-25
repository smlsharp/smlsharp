open SMLUnit.Test SMLUnit.Assert

type t1 = d1
type t2 = d2
type 'a t3 = 'a d3
type t4 = d4

val v1 : t1 = dv1
val v21 : t2 = dv21
val v22 : t2 = dv22
val v31 : int t3 = dv31
val v31 : int t3 = dv32

val _ = assertTrue (dv411 <> dv42)
val _ = assertTrue (dv411 = dv412)
val _ = assertTrue (dv61 <> dv62)
