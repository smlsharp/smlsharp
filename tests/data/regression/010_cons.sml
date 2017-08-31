infix 4 ::
val x = 1 :: nil
(*
2011-08-12 ohori

This causes bug exception in RecordCompilation.
[BUG] tpappTy:int(t0) * int(t0) list(t14) -> int(t0) list(t14), {int(t0)}
    raised at: ../types/main/TypesUtils.sml:848.9-855.20
   handled at: ../recordcompilation/main/RecordCompilation.sml:480.42
		../toplevel2/main/Top.sml:778.37
		main/SimpleMain.sml:269.53

FIXED. 2011-08-12 ohori
This is a bug in type inference.
Changed the code to pass polyFunTy to makeNewTermBody function
in processCon in ICAPPM case.

*)
