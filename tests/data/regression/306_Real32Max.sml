val _ = case Real32.toString (Real32.max (1.1, Real32.posInf)) of
          "inf" => ()
        | _ => raise Fail "Unexpected"

(*
2014-08-01 Sasaki

This code raises Fail exception unexpectedly since the assertion fails;

This is due to the bug of Real32.max.
*)
