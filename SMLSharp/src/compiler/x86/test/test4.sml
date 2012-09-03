(* test of tail call *)

val print = _import "prim_print" : string -> unit
val tostr = _import "prim_Int_toString" : __attribute__((alloc)) int -> string

fun f (0, k) = k 0 : int
  | f (n, k) = f (n - 1, fn x => (print (tostr x); print "\n"; k (x + n)))

val x = f (100, fn x => x)
val _ = (print (tostr x); print " =\n")
