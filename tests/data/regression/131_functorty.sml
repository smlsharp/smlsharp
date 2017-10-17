_interface "131_functorty.smi"
structure S = F(type t = int)

(*
2011-09-07 katsu

Type annotations of EXTERNVAR in 131_functorty.sml
and EXPORTVAR in 131_functorty2.sml are mismatched.

131_functorty.sml:

extern var _.F : ['a. ({1: 'a} -> {1: 'a}) -> {1: ['b. 'b -> 'b]}]

131_functorty2.sml:

export variable _.F(6) : ['a, 'b. ({1: 'a} -> {1: 'a}) -> {1: 'b -> 'b}]

*)


(*
2011-09-07 ohori

Fixed by writing up a type coercion checking (e, tau, sigma)
to verify that e of type tau can be coerceed to sigma.
The code is length and complicated. Need to review.

*)
