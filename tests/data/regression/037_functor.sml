functor F(P:sig type foo val x : foo end) =
struct
  datatype bar = A of P.foo
  fun f (y:P.foo) = (y, P.x)
end

(*
2011-08-21 ohori

This causes a BUG exception in EvalITy called form InferTypes
valrecopimization done
[BUG] EvalITy: non dty tfun in evalBuiltin
    raised at: ../types/main/EvalIty.sml:57.16-57.49
   handled at: ../typeinference2/main/InferTypes.sml:2682.33
		../typeinference2/main/InferTypes.sml:2973.28
		../toplevel2/main/Top.sml:759.65-759.68
		../toplevel2/main/Top.sml:861.37
		main/SimpleMain.sml:356.53

2011-08-21 ohori
Fixed by adding the case for "lifted type constructor" in EvalITy.

*)
