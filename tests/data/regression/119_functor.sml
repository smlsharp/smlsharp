_interface "119_functor.smi"
structure T = F ()

(*
2011-09-06 katsu

This causes an unexpected name error.

119_functor.smi:6.10-6.16 Error:
  (name evaluation CP-170) Provide check fails (missing type name) : T.S.t
*)


(*
2011-09-06 ohori

Fixed.
This is essentially the same bug as 109; the same treatment is needed
in compiling the functor interface.

*)
