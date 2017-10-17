val _ = case Date.fromString "" of 
          NONE => () | _ => raise Fail "Unexpected"

(*
2014-10-03 Sasaki

This code raises Fail exception unexpectedly only in 64-bit SML#
since the assertion fails.
*)
(*
2016-07-14 katsu
このチェンジセットの時点でこの問題は発生しない

  changeset:   7547:1183956ca6a8
  user:        tsasaki
  date:        Thu Jul 14 11:45:24 2016 +0900
  coerceTyがconstraintを返すように変更

*)
