structure X = F(S)

(*
2011-11-29 katsu

This causes BUG.

[BUG] InferType: var not found
    raised at: ../typeinference2/main/InferTypes2.sml:4230.31-4230.50
   handled at: ../toplevel2/main/Top.sml:758.65-758.68
                ../toplevel2/main/Top.sml:836.37
                main/SimpleMain.sml:368.53
*)
(*
2011-11-29 ohori

Fixed. This fix introduce a new term constructor in and after IDCalc.ppg:

    | ICEXEXN_CONSTRUCTOR of {path:path, ty:ty} * loc

which denotes external exception tag to be passed to a functor.

*)
