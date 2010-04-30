(* test of tail call 2; --xdoInlining=no *)

val print = _import "prim_print" : string -> unit
val tostr = _import "prim_Int_toString" : __attribute__((alloc)) int -> string

local
  fun f3 x = (x - 0x8, x + 0x8)
  fun f2 (x,y,z) = f3 (x + y + z)  (* 3 -> 1 *)
  fun f1 (x,y) = f2 (x,y,0x12)     (* 2 -> 3 *)
in
  fun g x =
      let
        val (x, y) = f1 (x,0x11)
      in
        (y,x)
      end
end

val (x,y) = g 0x10
val _ = (print (tostr x); print " "; print (tostr y); print " =\n")
