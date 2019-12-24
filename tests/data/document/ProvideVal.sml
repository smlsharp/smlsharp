val i = 1
val i8 = 0x7F
val i16 = 0x7FFF
val i32 = 0x7FFFFFFF
val i64 = 0x7FFFFFFFFFFFFFFF
val iInf = 0x8FFFFFFFFFFFFFFF

val w = 0w1
val w8 = 0wxFF
val w16 = 0wxFFFF
val w32 = 0wxFFFFFFFF
val w64 = 0wxFFFFFFFFFFFFFFFF

val r = 0.1
val r32 = 0.2
val c = #"A"
val s = "ABC"
val b = true

val ref1 = ref 1
val _ = (ref1 := 2)
val tuple1 = (1, "A")
val tuple2 = (2, "B")
val record1 = {A=1, B="A"}
val list1 = [1, 2, 3]

fun f1 x = x
fun f2 x = x + x
fun f3 x = x + x
val f4 = f2
val f5 = f1 f1

exception Exn1
fun f6 x = raise Exn1
fun f7 x = raise Exn1

val v1 = 1
val v1 = "A"
