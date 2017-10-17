_interface "082_functor.smi"

functor F (structure S1 : sig eqtype t end) =
struct
end
structure A = F (structure S1 = S)

(*
2011-08-27 katsu

This causes BUG at InferTypes.
A type error is expected.

[BUG] InferType: APPM_NOUNIFY
    raised at: ../typeinference2/main/InferTypes.sml:2266.30-2266.48
   handled at: ../typeinference2/main/InferTypes.sml:2295.49
                ../typeinference2/main/InferTypes.sml:3621.28
                ../toplevel2/main/Top.sml:766.65-766.68
                ../toplevel2/main/Top.sml:868.37
                main/SimpleMain.sml:359.53
*)


(*
2011-08-29 ohori

Fixed. Added a missing case of ERRORty in I.ICAPPM_NOUNIFY in InferType.sml.

*)
