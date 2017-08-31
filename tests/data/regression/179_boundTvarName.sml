fun f x = #name x
(*
2011-12-04 ohori

Bound type variable names in typed term is incorrect.
(TermFormat.formatBTB is changed to show its btvId)

val f(0) : ['a(32)#{name: 'b(31)(31)}, 'b(31). 'a(32)(32) -> 'b(31)(31)] =
 [
  'c(31),
  'd(32)#{name: 'c(31)(31)}.
   fn {x(1) : 'b(32)(32)} =>
    (#name ((x(1) : 'b(32)(32)) :'b(32)(32))) :'a(31)(31)
     :'a(31)(31)
 ]

In the term, 'c, 'd should be 'b and 'a.
*)

(*
2011-12-07 katsu

Fixed by changeset b9d1b9deb95f.
This is a bug of formatter of TPPOLYFN.
*)
