val _ = case Real32.toString (Real32.min (1.1, Real32.negInf)) of
          "~inf" => ()
        | _ => raise Fail "Unexpected"

(*
2014-08-01 Sasaki

This code raises Fail exception unexpectedly since the assertion fails;

This is due to the bug of Real32.min.
*)
