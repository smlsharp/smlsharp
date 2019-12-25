val ! = SMLSharp_Builtin.General.!
fun f x = ref x
val r = f 1234.5
val _ = if SMLSharp_Builtin.Real64.equal (!r, 1234.5)
        then ()
        else raise Fail "FIXME"

(*
2015-07-15 katsu

!r must be 1234.5 but the equality check (!r == 1234.5) fails.
*)
(*
2016-07-14 katsu
このチェンジセットの時点でこの問題は発生しない

  changeset:   7547:1183956ca6a8
  user:        tsasaki
  date:        Thu Jul 14 11:45:24 2016 +0900
  coerceTyがconstraintを返すように変更

*)
