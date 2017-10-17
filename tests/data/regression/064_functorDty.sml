functor F (A : sig
  datatype foo = A
  datatype bar = B
  datatype bas = C
  datatype hoge = H
end) =
struct
  fun f (x) = x
end

(*
2011-08-24 katsu

This causes BUG at NameEval.

[BUG] EvalITy: free tvar:'a(tv33)
    raised at: ../types/main/EvalIty.sml:73.20-73.79
   handled at: ../typeinference2/main/InferTypes.sml:3001.36
                ../typeinference2/main/InferTypes.sml:3478.28
                ../typeinference2/main/InferTypes.sml:3478.28
                ../toplevel2/main/Top.sml:766.65-766.68
                ../toplevel2/main/Top.sml:868.37
                main/SimpleMain.sml:359.53
*)

(*
2011-08-25 ohori

Fixed by 2611:6a75e4b92776
This is due to two bugs.
1. CONty of con is given through functor argument is not properly
   given a polytype in NamaEval.sml.
2. FUN_DTY tfun remains and should be interpreted in EvalITy.sml

*)

(* 2012-8-6 ohori
 The printer does not work well for this:
# use "064_functorDty.sml";
064_functorDty.sml:5.3-5.22 Warning: match nonexhaustive
      A.SOME x => ...
functor F
  (sig
    datatype 'a t = NONE | SOME of 'a
    
    
  end) =
    sig
      val f
    end
*)
(* 2012-8-7 ohori 
   Made an ad-hoc fix (4378:5e44dff2dce3) 
   by filtering out IDSPECCON in varE
   just before printing in module Reify.sml
*)
