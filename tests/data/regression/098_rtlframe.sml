val lt = SMLSharp_Builtin.Int32.lt
fun chr index =
    if lt (index, 0)
    then raise Bind
    else SMLSharp_Builtin.Char.chr index

(*
2011-09-01 katsu

This causes BUG at RTLFrame.

[BUG] union
    raised at: ../rtl/main/RTLUtils.sml:133.35-133.76
   handled at: ../toplevel2/main/Top.sml:868.37
		main/SimpleMain.sml:359.53
*)


(*
2011-09-02 ohori

This does not occurr. Perhaps it was caused by one of previous bug in
nameevaluation.

*)

(*
2011-09-02 katsu

This was a bug of register allocation due to changes of runtime types.
Fixed by changeset a3ec69ba38f6.

*)
