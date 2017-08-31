val a = VectorSlice.slice(Vector.fromList [1,2,3,4,5,6], 3, SOME 3);
val b = VectorSlice.sub(a, ~1);
(* 2014-01-27 
Subscript例外が発生しない．

# val a = VectorSlice.slice(Vector.fromList [1,2,3,4,5,6], 3, SOME 3);
val a = _ : int VectorSlice.slice
# val b = VectorSlice.sub(a, ~1);
val b = 3 : int
*)

(*
2014-01-29 katsu

fixed by changeset 399ad9803e1b
*)
