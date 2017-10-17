signature S =
sig
  datatype void = V of void
end
functor F(T : S) : sig
  structure T : S
end =
struct
  structure T = T
end

(*
2011-11-28 katsu

This causes a BUG.

[BUG] NormalizeTy: FUN_DTY
    raised at: ../nameevaluation/main/NormalizeTy.sml:185.39-185.52
   handled at: ../nameevaluation/main/NameEval.sml:1684.45
                ../nameevaluation/main/NameEval.sml:2460.31
                ../nameevaluation/main/NameEval.sml:2493.27-2493.30
                ../toplevel2/main/Top.sml:753.66-753.69
                ../toplevel2/main/Top.sml:836.37
                main/SimpleMain.sml:368.53

*)

(*
2011-11-28 ohori

Fixed

By allow FUN_DTY in structure. This happens when a structure in a functor signature
is replicated in the functor body.
*)
