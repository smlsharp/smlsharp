_interface "056_doubledval.smi"
val x = 1
val x = 2

(*
2011-08-23 katsu

This code must be rejected by NameEval, but it passes and causes BUG at
StaticAllocation due to doubled global symbol.

[BUG] unionTopEnv:
SML1x:  GLOBALVAR(2 : ATOMty : 0x4)
SML1x:  GLOBALVAR(2 : ATOMty : 0x4)
    raised at: ../yaanormalization/main/StaticAllocation.sml:37.19-40.76
   handled at: ../toplevel2/main/Top.sml:868.37
                main/SimpleMain.sml:359.53
*)

(*
2011-08-24 ohori

Fixed. 

*)
