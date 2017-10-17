structure A =
struct
  val x = Int.abs (* builtin primitives *)
end
functor F(X:sig val x: int -> int end) =
struct
  val y = X.x
end
structure A = F(A)

(* 2012-1-8 ohori
This causes unexpected type error.
193_primitiveArg.sml:9.15-9.18 Error:
  (type inference 007) operator and operand don't agree
  operator domain: int(t0[]) -> int(t0[])
  operand: unit(t8[])

This should be a bug in name evaluation.
*)
(* 2012-1-8 ohori
fixed by 3775:d2de32fa8be4
*)

