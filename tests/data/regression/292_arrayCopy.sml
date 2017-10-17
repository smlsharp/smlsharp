(
 Array.copy {di=0x7fffffff, dst=Array.array(10,0), src=Array.array(10,0)};
 raise Fail "ng"
)
handle Subscript => ()

(*
2014-01-29 katsu

This must raise Subscript.
*)

(*
2014-01-29 katsu

fixed by changeset 6829c729793c
*)
