exception SysErr of string
infix 4 =
fun cstrToString (x:char ptr) : string =
    if x = SMLSharp_Builtin.Pointer.null ()
    then raise SysErr "null pointer exception"
    else (* str_new x *) raise Fail "fail"

(*
2011-08-17 ohori

This causes a BUG exception in 

aigeneration done
[BUG] selectCompare: w == Vp
    raised at: ../rtl/main/X86Select.sml:1642.17-1645.78
   handled at: ../toplevel2/main/Top.sml:828.37
		main/SimpleMain.sml:269.53

*)

(*
2011-08-21 katsu

Fixed by changeset 1c7d57679e09.

This bug caused due to ATOMty.
This is fixed by translating AnnotatedTypes into YAANormal types
more accurately at ToYAANormal.
*)
