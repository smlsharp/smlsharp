structure T :> sig
  eqtype t
  type s = t * t
  val x : s -> s
end =
struct
  type t = int * int
  type s = t * t
  fun x (x:s) = x
end

(*
2011-09-09 katsu

This causes an unexpected signature mismatch error.

138_sig.sml:1.11-8.3 Error:
  (name evaluation 210) Signature mismatch (datatype): T.s(1)

*)

(*
2011-11-25 ohori

Fixed.
*)
