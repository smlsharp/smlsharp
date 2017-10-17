fun f (_:undefined_type) = ()

(*
2011-08-22 katsu

This causes BUG.

[BUG] NameEval(EvalTy): LookupTstr
    raised at: ../nameevaluation/main/EvalTy.sml:88.22-88.38
   handled at: ../nameevaluation/main/NameEval.sml:2695.31
		../nameevaluation/main/NameEval.sml:2707.27-2707.30
		../toplevel2/main/Top.sml:756.66-756.69
		../toplevel2/main/Top.sml:868.37
		main/SimpleMain.sml:359.53
*)

(*
2011-08-n23 ohori

FIXED. This is due to a debug code for undefined tycon that should be
removed in EvalTy.sml. 
*)
