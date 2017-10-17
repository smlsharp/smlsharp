val a = ArraySlice.slice(Array.fromList [0,1,2,3,4,5,6,7,8,9], 3, SOME 3)
val b = ArraySlice.findi (fn (i,x) => i = 0) a
val c = VectorSlice.slice(Vector.fromList [0,1,2,3,4,5,6,7,8,9], 3, SOME 3)
val d = VectorSlice.findi (fn (i,x) => i = 0) c

val _ = case b of SOME (0,3) => () | _ => raise Fail "ng"
val _ = case d of SOME (0,3) => () | _ => raise Fail "ng"

(* 2014-01-30 ohori
val a = _ : int ArraySlice.slice
val b = SOME (3,3) : (int * int) option
val c = _ : int VectorSlice.slice
val d = SOME (3,3) : (int * int) option

両方ともSOME(0,3)のはず．
*)
(*
2016-07-14 katsu
このチェンジセットの時点でこの問題は発生しない

  changeset:   7547:1183956ca6a8
  user:        tsasaki
  date:        Thu Jul 14 11:45:24 2016 +0900
  coerceTyがconstraintを返すように変更

*)
