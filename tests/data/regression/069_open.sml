_interface "069_open.smi"
open S

(*
2011-08-25 katsu

This causes BUG at NameEvalInterface.

[BUG] NameEvalInterface: IDEXVAR in env
    raised at: ../nameevaluation/main/CheckProvide.sml:157.23-157.43
   handled at: ../nameevaluation/main/CheckProvide.sml:486.46
                ../nameevaluation/main/CheckProvide.sml:497.35
                ../nameevaluation/main/NameEval.sml:2751.31
                ../nameevaluation/main/NameEval.sml:2759.27-2759.30
                ../toplevel2/main/Top.sml:756.66-756.69
                ../toplevel2/main/Top.sml:868.37
                main/SimpleMain.sml:359.53
*)

(*
2011-08-27 ohori

Fixed.


*)
