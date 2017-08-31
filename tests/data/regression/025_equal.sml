infix =
val puts = _import "puts" : string -> int
datatype term
  = Var of int
  | Term of string * term list
(*
v3*(v2*(v5*v4))
This is the term first failed on the test M'=N' in processf
*)
val x = Term("*", [Var 3, Term("*", [Var 2, Term("*", [Var 5, Var 4])])])
val y = Term("*", [Var 3, Term("*", [Var 2, Term("*", [Var 5, Var 4])])])
val z = if x = y then puts "OK" else puts "NG"

(*
2011-08-17 ohori

[BUG] transformExp: CAMERGE
    raised at: ../toyaanormal/main/ToYAANormal.sml:592.31-592.66
   handled at: ../toplevel2/main/Top.sml:828.37
		main/SimpleMain.sml:269.53

A Note:

This cases a BUG exception. This is related to knuth-bendix fails.
In processf, it tests equality on the same term of this by polymorphic
equality, which fails. 

*)

(*
2011-08-17 katsu

Fixed by changeset c76fdbd14dee.
This is a minor bug of ToYAANormal.
*)
