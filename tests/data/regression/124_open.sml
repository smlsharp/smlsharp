_interface "124_open.smi"
open S

(*
2011-09-06 katsu

"124_open.sml" must export variable "x", but it exports "S.x".

extern var S.x : int(t0[])
val S.x(0) : int(t0[]) = S.x
export variable S.x(0) : int(t0[])   (**** <==== this must be "x" ****)

*)


(*
2011-09-06 ohori

Fixed by get the external name and internal names right
in CheckProvide.sml

*)
