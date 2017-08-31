_interface "112_errmsg.smi"
structure S :> sig
  type t
end =
struct
  datatype t = T
end

(*
2011-09-05 katsu

This causes an error due to equality kind mismatch, but
error message says "arity" mismatch.

112_errmsg.smi:3.3-3.28 Error:
  (name evaluation CP-030) Provide check fails (datatype arity mistch) : S.t
*)
