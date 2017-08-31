signature S0 =
sig
  type t0
  type t1 = t0
end

signature S1 =
sig
  structure A0 : S0
  structure A1 : S0
  sharing A0 = A1
end

(*
2011-12-01 katsu

This causes a BUG.

[BUG] NameEval: non tfv (2)
    raised at: ../nameevaluation/main/EvalSig.sml:179.32-179.49
   handled at: ../nameevaluation/main/EvalSig.sml:341.33
                ../nameevaluation/main/NameEval.sml:2532.31
                ../nameevaluation/main/NameEval.sml:2565.27-2565.30
                ../toplevel2/main/Top.sml:753.66-753.69
                ../toplevel2/main/Top.sml:836.37
                main/SimpleMain.sml:368.53
*)


(*
2011-12-01 ohori

Fixed.
*)
