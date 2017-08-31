val x = 1;
val y = x;
fun f () = (x,y);

(*
2016-06-18 katsu

This causes BUG in interactive mode.

SML# 3.1.0-trial_join1 (2016-06-17 18:51:26 JST 772c2501217b) for x86_64-apple-darwin with LLVM 3.7.1
# val x = 1;
val x = 1 : int
# val y = x;
val y = 1 : int
# fun f () = (x,y);
Compiler bug:defineTopdecs: duplicated top symbol _SMLZN1x10E

*)

(*
2016-07-14 katsu
このチェンジセットの時点でこの問題は発生しない

  changeset:   7547:1183956ca6a8
  user:        tsasaki
  date:        Thu Jul 14 11:45:24 2016 +0900
  coerceTyがconstraintを返すように変更

*)
