val _ = Real.compare(1.23, Real.posInf * 0.0);

(*
2016-06-08 ohori

# val _ = Real.compare(1.23, Real.posInf * 0.0);
search_lpad failed
アボートしました
*)

(*
2016-07-14 katsu
このチェンジセットの時点でこの問題は発生しない

  changeset:   7547:1183956ca6a8
  user:        tsasaki
  date:        Thu Jul 14 11:45:24 2016 +0900
  coerceTyがconstraintを返すように変更

*)
