structure S :> sig
  type t
  type s = t list
end =
struct
  type t = int * int
  type s = t list
end

(*
2011-09-09 katsu

This causes an unexpected signature match error.

140_sig.sml:1.11-8.3 Error:
  (name evaluation 210) Signature mismatch (datatype): S.s(1)

*)

(*
2011-11-25 ohori

Fixed.
*)
