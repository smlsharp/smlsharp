_interface "075_builtin.smi"
open Array

(*
2011-08-27 ohori

This causes a BUG exception.

[BUG] NameEvalInterface: IDBUILTIN in env
    raised at: ../nameevaluation/main/CheckProvide.sml:171.23-171.45
   handled at: ../nameevaluation/main/CheckProvide.sml:513.46
		../nameevaluation/main/CheckProvide.sml:524.35
		../nameevaluation/main/NameEval.sml:2887.31
		../nameevaluation/main/NameEval.sml:2895.27-2895.30
		../toplevel2/main/Top.sml:756.66-756.69
		../toplevel2/main/Top.sml:868.37
		main/SimpleMain.sml:359.53
*)

(*
2011-08-27 ohori

FIXED.  
Probably, we should generate a eta-expanded term and rebind.
*)
