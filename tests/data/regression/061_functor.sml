_interface "061_functor.smi"
functor F () =
struct
  structure T = S
end
structure S2 = F()

(*
2011-08-24 katsu

This causes an unexpected type error.

061_functor.sml:6.16-6.18 Error:
  (type inference 054) operator and operand don't agree
  operator domain: unit(t7)
  operand: {1: int(t0)}
*)

(*
2011-08-24 ohori
Fixed by modifying the case for external variables in functor body.

*)
