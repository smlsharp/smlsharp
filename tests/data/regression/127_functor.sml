_interface "127_functor.smi"
functor F (A : sig exception E end) =
struct
  exception E = A.E
end

(*
2011-09-06 katsu

This causes an unexpected mismatch error.

127_functor.smi:1.9-4.3 Error:
  (name evaluation CP-431) Provide check fails (functor body signature mismatch)
  : F
*)


(*
2011-09-06 ohori

This was due to NameEvalInterface produce IDEXN for replicated exception.
Fixed. 

*)
