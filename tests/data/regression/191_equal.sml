infix - * =
infixr ::
val op - = SMLSharp_Builtin.Int32.sub_unsafe
val op * = SMLSharp_Builtin.Int32.mul_unsafe

fun loop1 0 = nil | loop1 n = (n * 0x1000000) :: loop1 (n-1)
fun loop2 (0,n) = () | loop2 (m,n) = (loop1 n; loop2 (m-1,n))
val _ = loop2 (10000,100)  (* fill heap with garbages *)

fun f (x,y,z) = (z,y,x)
val a = f (1, #"c", #"d")
val b = f (1, #"c", #"d")
val _ = if a = b then () else raise Fail "NOT EQUAL"

(*
2011-12-26 katsu

This causes an unexpected uncaught exception (Fail "NOT EQUAL").

The record "a" and "b" are 8-byte data of the form
  64 63 __ __ 01 00 00 00
where __ indicates the padding between record fields.

Record allocation code does not clear the padding areas, and some
garbage data will be left there. The equality check "a = b", which
is performed by byte-to-byte comparison, may fail due to difference
of garbage data.

In this case, "a" should be 64 63 00 01 01 00 00 00, and "b" should
be 64 63 00 03 01 00 00 00, so the equality check fails.

*)

(*
2011-12-27 katsu

fixed by changeset e418e3019a23.

If there may be some padding area in the record, compiler generates
code which fills allocated memory block with zero before record
initialization.

*)
