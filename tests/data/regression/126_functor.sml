_interface "126_functor.smi"
functor F () =
struct
  exception E
end

(*
2011-09-06 katsu

This causes an unexpected mismatch error.

126_functor.smi:1.9-4.3 Error:
  (name evaluation CP-431) Provide check fails (functor parameter signature
  mismatch) : F
*)


(*
2011-09-06 ohori

Fixed.

*)
