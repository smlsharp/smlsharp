exception Failure
fun f () = raise Failure
val _ = (f()) handle _ => 1

(*
2011-08-16 ohori

This causes segmentation fault, due to  a wrong exception record generated
in the body of f. 

*)

(*
2011-08-16 katsu

Fixed by changeset b9eae61f9c71.
This is due to wrong compilation of ToYAANormal.

*)
