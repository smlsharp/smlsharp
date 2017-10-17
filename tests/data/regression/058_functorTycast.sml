val printf = _import "printf" : (string,...(int)) -> int
functor F(P:sig type foo val x : foo end) =
struct
  datatype bar = A of P.foo
  fun f (y:bar) = (y, P.x)
end;
structure AP = struct type foo = int val x = 1 end
structure A = F(AP);
val y = #1 (A.f(A.A 99));
val z = A.A 1;
val (A.A w) = z
val _ = printf ("%d\n", w)
(*
2011-08-23 ohori

This results in type error.

085_functorTycast.sml:10.13-10.22 Error:
  (type inference 007) operator and operand don't agree
  operator domain: {FREEBTV(29)}bar(t31)
  operand: bar(t33)

Fixed by coded up tycast treatment in InferTypes.sml

*)
