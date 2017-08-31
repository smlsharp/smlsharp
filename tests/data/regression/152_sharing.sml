signature S0 =
sig
  type t
end
signature S1 =
sig
  structure K1 : S0
  structure K2 : S0
end
signature S2 =
sig
  structure T1 : S1
  structure T2 : S1
  sharing T1 = T2
end
signature S3 =
sig
  structure T1 : S1
  structure T2 : S2
  sharing T1 = T2.T1
end

(*
2011-11-28 katsu

This causes a BUG.

[BUG] IDTypes: tfvid: ReALIZED
    raised at: ../types/main/IDTypes.ppg.sml:687.29-687.50
   handled at: ../nameevaluation/main/EvalSig.sml:267.65-267.68
                ../nameevaluation/main/EvalSig.sml:277.33
                ../nameevaluation/main/NameEval.sml:2460.31
                ../nameevaluation/main/NameEval.sml:2493.27-2493.30
                ../toplevel2/main/Top.sml:753.66-753.69
                ../toplevel2/main/Top.sml:836.37
                main/SimpleMain.sml:368.53
*)

(*
2011-11-28 ohori

fixed 

Processing multiple sharing constraints temporarly produce non-canonical tfuns, so
tfun equality cheking must be done with dereferencing REALIZED tfuns.

*)
