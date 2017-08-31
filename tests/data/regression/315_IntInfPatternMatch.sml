val _ = case (0xf : intInf) of 0xf => () | _ => raise Fail "Unexpected"

(*
2014-10-03 Sasaki

This code raises Fail exception unexpectedly since the assertion fails.
*)

(*
2014-10-05 katsu

fixed by changeset b38098ae9176
*)
