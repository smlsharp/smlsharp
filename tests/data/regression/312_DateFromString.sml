val a = Date.fromString " Thu Jan  1 00:00:00 1970"

val _ = case a of SOME _ => () | _ => raise Fail "Unexpected"

(*
2014-08-20 Sasaki

This code raises Fail exception unexpectedly since the assertion fails.

Date.fromString should ignore possible initial whitespace.
*)
