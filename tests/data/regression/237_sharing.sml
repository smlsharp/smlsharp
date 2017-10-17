signature S =
sig
  datatype t1 = D
  type t2
  sharing type t1 = t2
  val x : int
end

functor F (A : S) : S =
struct
  open A
end

(*
2012-09-19 katsu

This causes an unexpected signature mismatch error.

237_sharing.sml:8.9-11.3 Error:
  (name evaluation 230) Signature mismatch (datatype): t2

*)

(*
2012-09-21 ohori

Fixed by adding the case for FUN_DTY in SigCheck.
*)
