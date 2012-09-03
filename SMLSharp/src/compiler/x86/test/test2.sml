(* test of memory allocation *)

val print = _import "prim_print" : string -> unit
val tostr = _import "prim_LargeInt_toString" : __attribute__((alloc)) IntInf.int -> string 

fun f (l,0:IntInf.int) = l
  | f (l,n) = (print (tostr n); print "\n";
               if n mod 2 = 0 then f (nil, n - 1) else f (n::l, n - 1))

val x = f (nil, 200)
