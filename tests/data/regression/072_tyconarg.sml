type 'a t = 'a list * int
fun f (x:t) = ()

(*
2011-08-25 katsu

This code causes BUG at InferTypes.
A type error is expected.

[BUG] EvalITy: free tvar:'a(tv29)
    raised at: ../../types/main/EvalIty.sml:75.20-75.79
   handled at: ../typeinference2/main/InferTypes.sml:2471.57
                ../typeinference2/main/InferTypes.sml:2435.19
                ../typeinference2/main/InferTypes.sml:3511.28
                ../toplevel2/main/Top.sml:766.65-766.68
                ../toplevel2/main/Top.sml:868.37
                main/SimpleMain.sml:359.53

*)

(*
2011-08-27 ohori

Same bug as 071 and is fixed.

*)
