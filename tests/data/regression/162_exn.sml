structure S1 =
struct
  exception E
end
structure S2 = S1

(*
2011-11-29 katsu

This causes an unexpected name error.

162_exn.smi:7.13-7.20 Error:
  (name evaluation CP-330) Provide check fails (exception replication expected)
  : S1.E

*)

(*
2011-11-29 ohori
Fixed.
*)
