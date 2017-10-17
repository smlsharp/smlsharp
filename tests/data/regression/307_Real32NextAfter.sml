val a = Real32.posInf
val b = Real32.nextAfter (a, 0.0)
val c = Real32.toString b

val _ = case c of "inf" => () | _ => raise Fail "Unexpected"

(*
2014-08-01 Sasaki

This code raises Fail exception unexpectedly since the assertion fails.
*)
