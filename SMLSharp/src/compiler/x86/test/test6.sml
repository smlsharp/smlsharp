(* test of list *)

val print = _import "prim_print" : string -> unit
val tostr = _import "prim_Int_toString" : __attribute__((alloc)) int -> string

fun length [] = 0
  | length list =
    let
      fun scan [] result = result
        | scan (_ :: tail) len = scan tail (len + 1)
    in scan list 0 end

val L5 = 5 : IntInf.int
val L50 = 50 : IntInf.int
val L500 = 500 : IntInf.int
val L5000 = 5000 : IntInf.int
val L50000 = 50000 : IntInf.int
val rndv = [L50000, L5000, L500, L50, L5]
val x = length rndv
val _ = (print (tostr x); print " "; print " =\n")
