_interface "048_opaquesig.smi"
signature T =
sig
  type t 
end
structure S :> T =
struct
  type t = bool
end

(*
2011-08-22 katsu

This causes an unexpected name error.

048_opaquesig.smi:3.8-3.16 Error:
  (name evaluation 130) Provide check fail (type definition) : S.t
*)

(*
2011-08-23 ohori

Changed the tfun equality check in CheckProvide to check the original tfun
when the tfunDef has dtyKind of OPAQUE tfun.

*)
