val a = CharVectorSlice.mapi
	  (fn (x, y) => #"a")
	  (CharVectorSlice.slice ("123456", 2, NONE))

val _ = case a of "aaaa" => () | _ => raise Fail "Unexpected"

(*
2014-06-26 Sasaki

This code raises Fail exception unexpectedly since 
the assertion fails; variable a must be "aaaa" but "\^A\^@aa".

This is due to the bug of CharVectorSlice.mapi.
*)
