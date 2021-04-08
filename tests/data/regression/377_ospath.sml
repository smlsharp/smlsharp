val _ = OS.Path.mkCanonical "/あいうえお"

(*
This causes OS.Path.InvalidArc exception unexpectedly.
*)
