functor F(A : sig end) =
struct
  type t = int * int
end

(*
2011-11-25 katsu

This causes an unexpected mismatch error.

147_functor.smi:1.9-4.3 Error:
  (name evaluation CP-431) Provide check fails (functor body signature mismatch)
  : F
*)

(*
2011-11-25 ohori

Probably fixed. Need to review the functor body structure in CheckProvide.

*)
