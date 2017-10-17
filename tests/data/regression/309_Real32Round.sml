val _ = case Real32.round 2.8 of
          3 => () | _ => raise Fail "Unexpected"

(*
2014-08-01 Sasaki

This code raises Fail exception unexpectedly since the assertion fails.

This is due to definition of round.

fun round x = Real32.trunc (realTrunc x)
*)
