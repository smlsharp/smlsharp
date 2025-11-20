fun f () =
    let
      val g = fn x:'a => x
    in
      while true do fn x:'a => x;
      g 1;
      g true
    end

(*
2025-11-19 katsu

This must not be typechecked because 'a is scoped at fun, not val.
*)
