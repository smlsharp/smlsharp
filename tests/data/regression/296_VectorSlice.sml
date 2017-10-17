val a = VectorSlice.slice (Vector.fromList [1,2,3,4], 2, NONE)

val _ =
    VectorSlice.mapi (fn (x, y) => x) a 
    handle Subscript => raise Fail "Unexpected"

(*
2014-07-03 Sasaki

This code raises Fail exception unexpectedly since the assertion fails;

This is due to the bug of VectorSlice.mapi.
*)
