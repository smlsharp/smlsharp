(* test of list *)

val print = _import "prim_print" : string -> unit
val tostr = _import "prim_Int_toString" : __attribute__((alloc)) int -> string

fun foldr f initial list =
    let
      fun scan [] result = result
        | scan (head :: tail) result = f (head, scan tail result)
    in scan list initial end

val f1 = foldr (op +)
val g1 = (f1, f1)
val f2 = f1 0
val g2 = (f2, f2)
val x = f2 [1,2]
val _ = (print (tostr x); print " "; print " =\n")
