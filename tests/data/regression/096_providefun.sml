_interface "096_providefun.smi"

functor F (
A : sig
   type t = S.t
end
) =
struct
end

(*
2011-09-01 katsu

This causes an unexpected name error.

096_providefun.smi:5.14-5.16 Error:
  (name evaluation 0621) unbound type constructor or type alias: S.t

*)

(*
2011-09-02 ohori

Fixed by adding the case for TFUN_DTY in eqTfunkind in sigEq for the case
of type t = ty, where t is bound to TFUN_DTY.

*)
