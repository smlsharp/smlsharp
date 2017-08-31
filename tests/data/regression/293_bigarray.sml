fun f 0 = ()
  | f n =
    let
      val a = Array.array (1440000, 0.0)
    in
      Array.update (a, 10, 10.0);
      f (n-1)
    end

val _ = f 100

(*
2014-01-29 katsu

This causes bus error.
*)

(*
2014-01-29 katsu

fixed by changeset edef8b06b390
*)
