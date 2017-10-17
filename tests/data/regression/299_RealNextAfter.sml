val a = Real.posInf
val b = Real.nextAfter (a, 0.0)
val c = Real.toString b

val _ = case c of "inf" => () | _ => raise Fail "Unexpected"

(*
2014-07-11 Sasaki

This code raises Fail exception unexpectedly since the assertion fails.

The value of c = Real.maxFinite.
*)
