exception Failure
fun try_find_rec f a = (f a) handle Failure => a

(*
2011-08-14 ohori

val x = 1 handle Failure => 2n


This causes BUG exception perhaps in RTLRename

x86stabilize done
[BUG] renameGraph
    raised at: ../rtl/main/RTLRename.sml:379.27-379.52
   handled at: ../toplevel2/main/Top.sml:820.37
		main/SimpleMain.sml:269.53
*)

(*
2011-08-14 katsu

Fixed by changeset 2e9c8e24ec78.
This is a bug of BitmapANormalization.

*)
