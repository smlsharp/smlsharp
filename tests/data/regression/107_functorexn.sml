_interface "107_functorexn.smi"
structure S = F()

(*
2011-09-04 katsu

This causes an unexpected name error.

107_functorexn.smi:4.13-4.13 Error:
  (name evaluation CP-290) Provide check fails (exception type mistch) : S.E
*)

(*
2011-09-05 ohori

Fixed.
*)
