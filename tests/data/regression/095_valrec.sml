fun f x =
    let
      val s as () = x
    in
      f x
    end

(*
2011-09-01 katsu

This causes infinite loop at VALREC optimization.
*)


(*
2011-09-01 katsu

This bug disappears; I guess this caused infinite loop
in InferTypes due to the bug in isStrictVarPat.

*)
