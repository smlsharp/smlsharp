structure S : sig
  type t
  datatype d = D of t
end =
struct
  type t = int * int
  datatype d = D of t
end

(*
2011-09-09 katsu

This causes an unexpected signature mismatch error.

139_sig.sml:1.11-8.3 Error:
  (name evaluation 280) Signature mismatch (datatype): S.d(4)

*)

(*
2011-11-25 ohori

Fixed.
*)
