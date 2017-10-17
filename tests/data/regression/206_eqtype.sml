signature EqType =
sig
  eqtype t
end;
structure NonEqType : EqType =
struct
  type t = real
end;

(*
2012-07-12 fukasawa

This is accepted, but this should be rejected.
eqtype specification allow only equality type.
*)

(*
2012-07-13 ohori

Fixed by 4307:23e90a7167c9
*)
