 val _ =
     let
       val n : int = (0w1 : word) (* 型不一致でエラー *)
 
       fun f1 x y = x y
       val v1 = f1 (fn a => a) true
       val v2 = f1 (fn a => a) "A" (* 上記の型不一致エラー発生時のみエラーになる *)
     in
       ()
     end;
