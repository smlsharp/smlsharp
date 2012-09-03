(* test of polymorphic record *)

val print = _import "prim_print" : string -> unit
val tostr = _import "prim_Int_toString" : __attribute__((alloc)) int -> string 

fun f ((x,y,z),l,0) = (z,y,x)
  | f ((x,y,z),l,n) =
    let val w = (x,y,z+n)
    in print (tostr n); print "\n"; f (w,w::l,n-1)
    end

val (z,y,x) = f (("hoge", 0.555, 0), nil, 200)
val _ = (print (tostr z); print " "; print x; print "\n")
