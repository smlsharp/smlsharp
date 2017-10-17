_interface "021_export.smi"
fun f (x:int) = x

(*
2011-08-15 katsu

This causes BUG at BitmapANormalization due to undefined variable.

[BUG] normalizeVar:0
    raised at: ../bitmapanormalization/main/BitmapANormalization.sml:75.34-75.81
   handled at: ../toplevel2/main/Top.sml:824.37
		main/SimpleMain.sml:269.53

RecordUnboxing seems to rename local variables incompletely.

Static Analysis:
val f(0) = fn x(1) => x(1)
export val f(0)

RecordUnboxing:
val $2(2) = fn x(1) => x(1)
export val f(0)    (* <---- ???? *)
*)

(*
2011-08-15 katsu

Fixed by changset e096741507aa and b10743f200f3.
After fixing the bug of RecordUnboxing, Another bug was caused at
ToYAANormal, but it is also fixed by changeset e9e012541803, and
077fed1a5fde.
*)
