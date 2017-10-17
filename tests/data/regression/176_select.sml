fun g x = #1 x
fun f x = (#name x, x)

(*
2011-12-01 katsu

This causes BUG at ClosureConversion.

[BUG] computeFrameBitmap
    raised at: ../closureconversion/main/ClosureConversion.sml:542.38-542.70
   handled at: ../toplevel2/main/Top.sml:836.37
                main/SimpleMain.sml:368.53
*)

(*
2011-12-07 katsu

Fixed by changeset 8dd2b53b6a8f.
*)
