_interface "042_typerep.smi"
val x = (S.NONE, S.SOME 1)

(*
2011-08-21 katsu

This causes unexpected name error.

042_typerep.sml:2.10-2.15 Error: unbound variable: S.NONE
042_typerep.sml:2.18-2.23 Error: unbound variable: S.SOME

*)

(*
2011-08-22 ohori

Fixed by rebinding varE in TSTR in NameEvalInterface.

*)
