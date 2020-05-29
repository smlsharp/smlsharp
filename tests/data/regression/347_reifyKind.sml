val _ = f 3;
(* 
  Segmentation faultを起こす。
  原因は、インターフェイスファイルに#reifyが宣言されていないため。
*)
