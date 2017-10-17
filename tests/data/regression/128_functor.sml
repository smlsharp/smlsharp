_interface "128_functor.smi"
(*
_require "128_functor2.smi"
structure S =
struct
  exception E
end

128_functor2.smi
functor F (A : sig exception E end) =
struct
  exception E = A.E
end

*)
structure S = F (exception E)

(*
2011-09-06 katsu

This causes an unexpected mismatch error.

128_functor.smi:4.13-4.13 Error:
  (name evaluation CP-270) Provide check fails (generative exception definition
  expected) : S.E
*)


(*
2011-09-06 ohori

Fixed.
IDEXN in provide clause can be matched against IDEXNREP in structure.
NEED to check that this will not allow any type error.
*)
