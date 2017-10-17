fn x => OS.IO.poll (nil, SOME (Time.now ()));
fn x => OS.FileSys.setTime (".", SOME (Time.now()));
(* 2014-01-26 ohori
  これらは，対話型モードで，型エラーとなる．
  原因は，完全に分かっていないが，おそらく，SMLSharp_XXXのidを
  インターフェイスファイルでreplicateしていることに関するものであろう．

  とりあえず，prelude.smiからSMLSharp_XXX.smiをincludeするとエラーは消える．

(interactive):1.8-1.43 Error:
  (type inference 008) operator and operand don't agree
  operator domain: SMLSharp_OSIO.poll_desc list * Time.time option
          operand: SMLSharp_OSIO.poll_desc list * Time.time option
*)
(*
2016-07-14 katsu
このチェンジセットの時点でこの問題は発生しない

  changeset:   7547:1183956ca6a8
  user:        tsasaki
  date:        Thu Jul 14 11:45:24 2016 +0900
  coerceTyがconstraintを返すように変更

*)
