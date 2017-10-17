structure S :> sig
  type t
  datatype t2 = X of t
end =
struct
  datatype t2 = X of t2 * t2
  type t = t2 * t2
end

(*
2011-09-09 katsu

This causes an unexpected signature mismatch error.

136_sig.sml:1.11-8.3 Error:
  (name evaluation 280) Signature mismatch (datatype): S.t2(4)
*)

(*
2011-09-10 ohori

Fixed.

*)
