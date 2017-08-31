_interface "059_opaqueint.smi"
infix =
val y = f 0 : int  (* unity "t" and "int" *)

(*
2011-08-24 katsu

This should cause a type error since type "t" declared in 059_opacueint2.smi
is opaque.
*)

(*
2011-08-24 ohori

Fixed. (tfun -> absTfun in NameEvalInterface.sml).

*)
