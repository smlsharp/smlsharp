_interface "132_overload.smi"
fun f x y = (x < y; x : string)

(*
2011-09-07 katsu

This causes infinite loop at InferTypes.
A type error is expected.
*)

(*
2011-09-07 ohori

Fixed.

This is due to the oprimSelector printer generating 
an infinit message. 

*)
