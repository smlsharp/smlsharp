val x = JSON.import "1";
_jsoncase x of
   y:bool => raise Fail "does not happen"
 | x:int => "OK should be printed"

(*
2016-06-07 ohori
_jsoncaseで，２番目以降のパターンが試みられない．

# val x = JSON.import "1";
val x = _ : JSON.void JSON.dyn
# _jsoncase x of y:bool => "does not happen" | x:int => "OK should be printed";
uncaught exception JSON.RuntimeTypeError at src/json/main/JSONImpl.sml:126
*)

(*
2016-07-14 katsu
このチェンジセットの時点でこの問題は発生しない

  changeset:   7547:1183956ca6a8
  user:        tsasaki
  date:        Thu Jul 14 11:45:24 2016 +0900
  coerceTyがconstraintを返すように変更

*)
