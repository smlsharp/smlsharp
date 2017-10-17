val a = Date.toString (Date.fromTimeLocal Time.zeroTime)
val _ = case a of "Thu Jan  1 09:00:00 1970" => ()
               |  _ => raise Fail "Unexpected"



(*                                                                                                                                                      
2014-07-24 Osaka                                                                                                                                       
イギリスのロンドンと指定した値域の間の時差が２回足された値が出力される模様
 
*)
