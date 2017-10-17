val x = case f 1234 of A a => g a | B _ => 0
val _ = case x of 1234 => () | _ => raise Fail "must be 1234"

(*
2016-04-02 katsu

This causes segmentation fault.
*)
(*
2017-01-27 katsu

fixed by changeset 90f06719210c
*)
