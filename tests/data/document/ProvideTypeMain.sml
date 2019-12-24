open SMLUnit.Test SMLUnit.Assert
val i : i = 1 : int
val i8 = 0xFF : int8
val i16 : i16 = 0x7FFF : int16
val i32 : i32 = 0x7FFFFFFF : int32
val i64 : int64 = 0x7FFFFFFFFFFFFFFF : int64
val iInf : iInf = 0x8FFFFFFFFFFFFFFF : intInf

val w : w = 0w1 : word
val w8 : w8 = 0wxFF : word8
val w16 : w16 = 0wxFFFF : word16
val w32 : w32 = 0wxFFFFFFFF : word32
val w64 : w64 = 0wxFFFFFFFFFFFFFFFF : word64

val r : r = 0.1 : real
val r32 : r32  = 0.2 : real32
val c : c = #"A"
val s : s = "ABC"
val b : b = true

val ref1 : ref1 = ref 1
val tuple1 : tuple1 = (1, "A")
val tuple2 : tuple2 = (2, "B")
val record1 : record1 = {A=1, B="A"}
val list1 : list1 = [1, 2, 3]
val list2i : int list2 = [1, 2, 3]
val list2s : string list2 = ["A", "B", "C"]

fun (f1 : 'a f1) x  = x
val f2 : f2 = f1
val f3 : f3 = f1
fun (f4 : ('a, string) f4) x = "A"

