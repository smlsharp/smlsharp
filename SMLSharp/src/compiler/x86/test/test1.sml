(* test of exception *)

val print = _import "prim_print" : string -> unit
val tostr = _import "prim_Int_toString" : __attribute__((alloc)) int -> string 

fun f 0 = raise Fail "hoge\n"
  | f n = (print (tostr n); print "\n"; f (n - 1) + 1)

val _ = f 10 handle Fail s => (print s; raise Fail "unhandled")
