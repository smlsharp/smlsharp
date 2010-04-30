(* test of array *)

val print = _import "prim_print" : string -> unit
val tostr = _import "prim_Int_toString" : __attribute__((alloc)) int -> string

val x = SMLSharp.PrimArray.vector (0, 0)
val x = SMLSharp.PrimArray.length x
val _ = (print (tostr x); print "\n")
