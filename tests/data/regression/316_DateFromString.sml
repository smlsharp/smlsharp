val a = Date.fromString " Mon Nov 10 11:10:23 2014"

val _ = case a of SOME _ => () | _ => raise Fail "Unexpected"

(*
2014-10-03 Sasaki

This code raises Fail exception unexpectedly since the assertion fails.
This caused by not ignoring possible initial whitespace.

*)
