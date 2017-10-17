val a = Real.Math.pow (1.0, Real.posInf)
val _ = case Real.isNan a of true => () | _ => raise Fail "Unexpected"

(*
2014-07-25 Sasaki

This code raises Fail exception unexpectedly since 
the assertion fails.

Basis Library defines pow (+1, +infinity) = NaN.
Variable a is 1.0 .
*)
