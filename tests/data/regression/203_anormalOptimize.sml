if 1 > 2 then ("NG"; raise Fail "ng") else "OK";

(*
2012-06-16 ohori
This source prints "NG". This is due to the bug in ANormalOptimizer.sml.

2012-06-16 ohori. Fixed by 4288:e07d59341ecf.

*)

