type 'a t = 'a list
fun f (x:t) = ()

(*
2011-08-25 katsu

This must cause a type error due to tycon arity mismatch.

*)

(*
2011-08-27 ohori

Fixed by adding arity check code in EvalTy.

*)
