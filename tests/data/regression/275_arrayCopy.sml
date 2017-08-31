val array0 = Array.array(0,0)
val _ = Array.copy{src=array0, dst=array0, di=0}
(* 2014-01-25 
  uncaught exception: Subscript
  アボートしました
  仕様上，正常終了するはず．
*)
