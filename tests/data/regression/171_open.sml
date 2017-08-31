structure A =
struct
  exception E
end
open A

(*
2011-11-30 katsu

This causes an unexpected mismatch error.

171_open.smi:5.11-5.17 Error:
  (name evaluation CP-330) Provide check fails (exception replication expected)
  : A.E
*)

(*
2011-11-30 ohori

This is the same bug as 170 and was fixed.

*)
