infixr ::
fun f (nil:'a list) = ()
  | f (h::t) = f t

(*
2013-07-18 katsu

This causes BUG when -ddoUncurryOptimization=no is specified.

[BUG] InferType: illeagal utvar instance in UserTvarNotGeneralized  check
*)
(*
2013-08-07 ohori

Fixed by 

*)
