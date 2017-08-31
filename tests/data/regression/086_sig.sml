_interface "086_sig.smi"
signature S = sig datatype must_be_datatype = X end
structure A : S = T

(*
2011-08-29 katsu

This causes BUG at NameEval.
A signature mismatch error is expected.

[BUG] NameEval: id not found
    raised at: ../nameevaluation/main/NameEval.sml:1603.53-1603.71
   handled at: ../nameevaluation/main/NameEval.sml:2930.31
                ../nameevaluation/main/NameEval.sml:2951.27-2951.30
                ../toplevel2/main/Top.sml:756.66-756.69
                ../toplevel2/main/Top.sml:868.37
                main/SimpleMain.sml:359.53
*)

(*
2011-08-31 ohori

Fixed. I have to go over the error propagation in NameEval and other
subordinate modules.

*)
