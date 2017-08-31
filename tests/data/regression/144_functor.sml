functor F(A : sig end) :> sig type t end =
struct
  datatype t = E
end

(*
2011-09-11 katsu

This causes an unexpected name error.

144_functor.smi:1.9-4.3 Error:
  (name evaluation CP-431) Provide check fails (functor body signature mismatch)
  : F
*)


(*
2011-11-25 ohori

fixed
*)
