functor F(A : sig type t end) :> sig type v end =
struct
  type v = A.t
end

(*
2020-05-18 katsu

This causes the following unexpected compile error.

363_functor.smi:1.8-4.2 Error:
  (name evaluation "CP-720") Provide check fails (functor body signature
  mismatch): F

*)
