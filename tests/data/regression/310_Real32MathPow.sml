val a = Real32.Math.pow (1.0, Real32.posInf)
val _ = case Real32.isNan a of true => () | _ => raise Fail "Unexpected"

(*
2014-08-01 Sasaki

This code raises Fail exception unexpectedly since the assertion fails.

Basis Library defines pow (+1, +infinity) = NaN.
Variable a is 1.0 .
*)
