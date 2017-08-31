signature S =
sig
  structure A : sig end
  structure B : sig end
  sharing type A.undefined_type = B.undefined_type
end

(*
2011-08-27 katsu

This causes BUG at NameEval.
A name error is expected.

[BUG] NameEval: no share list2
    raised at: ../nameevaluation/main/EvalSig.sml:246.28-246.48
   handled at: ../nameevaluation/main/EvalSig.sml:263.33
                ../nameevaluation/main/NameEval.sml:2878.31
                ../nameevaluation/main/NameEval.sml:2897.27-2897.30
                ../toplevel2/main/Top.sml:756.66-756.69
                ../toplevel2/main/Top.sml:868.37
                main/SimpleMain.sml:359.53
*)

(*
2011-08-28 ohori

Fixed by stop processing if there is no longids to process
in EvalSig.sml.


*)
