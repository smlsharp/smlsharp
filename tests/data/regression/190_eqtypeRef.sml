datatype foo = WWWWWWWWW of {A:(int -> int) ref, B:int};
fun f (x:foo, y:foo) =  x = y

(* 2011-12-24 ohori
This causes unexpected type error.
Something should be wrong with maximize eq in datatype compilation.

temp.sml:2.25-2.29 Error:
  (type inference 019) operator and operand don't agree
  operator domain: ''P * ''P
  operand: foo(t394[]) * foo(t394[])
*)

(* 2012-1-2 ohori
Fixed by treating "ref" specially in NormalizeTy.sml.
BuiltinTypes must be re-written to deal uniformly with this case.
*)
