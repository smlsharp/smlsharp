signature S =
sig
  structure T1 : sig type t end
  structure T2: UNDEFINED_SIGNATURE
  sharing type T1.t = T2.t
end

(*
2011-11-28 katsu

This causes BUG.
An undefined signature error is expected.

uncaught exception: ProcessShare: ProcessShare
    raised at: ../nameevaluation/main/EvalSig.sml:295.44-295.56
   handled at: ../nameevaluation/main/NameEval.sml:2460.31
                ../nameevaluation/main/NameEval.sml:2493.27-2493.30
                ../toplevel2/main/Top.sml:753.66-753.69
                ../toplevel2/main/Top.sml:836.37
                main/SimpleMain.sml:368.53
*)

(*
2011-11-28 ohori

fixed

*)
