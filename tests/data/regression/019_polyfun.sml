fun f x = 1

(*
2011-08-13 ohori

This causes BUG perhaps in X86Emit.

  x86frame done
  [BUG] slotIndex: 1
      raised at: ../rtl/main/X86Emit.sml:52.23-53.77
     handled at: ../toplevel2/main/Top.sml:820.37
  		main/SimpleMain.sml:269.53

*)

(*
2011-08-14 katsu

fixed by changeset 1c7302cb2026.
This is due to a bug of ClosureConversion.

*)
