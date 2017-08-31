functor F (
  eqtype t2
  val f : t2 -> int
) :>
sig
  eqtype t1
  val f : t1 -> int
end
where type t1 = t2
= struct
    type t1 = t2
    val f = f
end

(*
2011-08-27 katsu

This causes BUG at InferTypes.

uncaught exception: EVALTFUN: EVALTFUN
    raised at: ../types/main/EvalIty.sml:63.15-63.75
   handled at: ../typeinference2/main/InferTypes.sml:1861.63
		../typeinference2/main/InferTypes.sml:3621.28
		../typeinference2/main/InferTypes.sml:3621.28
		../toplevel2/main/Top.sml:766.65-766.68
		../toplevel2/main/Top.sml:868.37
		main/SimpleMain.sml:359.53
*)

(*
2011-08-29 ohori

FIXED in reduceEnv in NormalizeTy by adding the missing reduction to varE.

Perhaps we should add normalization in EvalIty.sml.

*)
