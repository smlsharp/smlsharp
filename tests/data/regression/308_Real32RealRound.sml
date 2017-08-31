val a = Real32.realRound 2.5
val b = Real32.toString a

val _ = case b of "2.0" => () | _ => raise Fail "Unexpected"

(*
2014-08-01 Sasaki

This code raises Fail exception unexpectedly since the assertion fails.

The value of a = 3.0.
*)
