functor F (A : sig type undefined_type end) =
struct
end
structure S = F()

(*
2011-08-24 katsu

This causes BUG.
An signature mismatch error is expected.

[BUG] NameEval: tstr not found
    raised at: ../nameevaluation/main/NameEval.sml:1959.41-1959.61
   handled at: ../nameevaluation/main/NameEval.sml:2220.15
                ../nameevaluation/main/NameEval.sml:2722.31
                ../nameevaluation/main/NameEval.sml:2735.27-2735.30
                ../toplevel2/main/Top.sml:756.66-756.69
                ../toplevel2/main/Top.sml:868.37
                main/SimpleMain.sml:359.53
*)

(*
2011-08-24 ohori

Fixed. Stop processing functor application at signature mismatch
in NameEval.sml.

*)
