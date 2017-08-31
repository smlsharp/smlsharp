val printf = _import "printf" : (string,...(int)) -> int
functor F(P:sig type foo val x : foo end) =
struct
  datatype bar = A of P.foo
  fun f (y:P.foo) = (y, P.x)
end;
structure AP = struct type foo = int val x = 1 end
structure A = F(AP);
val y = #1 (A.f(99));
val z = A.A 1;
val (A.A w) = z
val _ = printf ("%d\n", w)
(*
2011-08-21 ohori

Need to write a type cast for functor application in InferType.

[BUG] InferType: not yet 3
    raised at: ../typeinference2/main/InferTypes.sml:1737.15-1737.30
   handled at: ../typeinference2/main/InferTypes.sml:2973.28
		../toplevel2/main/Top.sml:762.65-762.68
		../toplevel2/main/Top.sml:864.37
		main/SimpleMain.sml:356.53

2011-08-22 ohori
Fixed.

*)
