val _ = raise Match

(*
2011-08-17 katsu

Raise at toplevel causes SEGV.

*)

(*
2011-08-21 katsu

Fixed.
Uncaught exception handing was missing.

*)
