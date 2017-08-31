_interface "077_sigopaque.smi"

structure S :> sig
  type t
end =
struct
  datatype t = X
end

open S

(*
2011-08-27 katsu

This causes an unexpected name error.

077_sigopaque.smi:1.1-1.16 Error:
  (name evaluation 126) Provide check fails (datatype expceted) : t
*)

(*
2011-08-28 ohori

Fixed. Rewrote checkDatbind in CheckProvide.
*)
