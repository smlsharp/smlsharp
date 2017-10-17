structure X = F(S)

(*
2011-11-29 katsu

This causes an unexpected type error.

166_functor.sml:1.15-1.18 Error:
  (type inference 007) operator and operand don't agree
  operator domain: exnTag(t13[])
  operand: unit(t7[])
*)

(*
2011-11-29 ohori
I believe this is the same bug as that of 163
*)
