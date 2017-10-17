val x = (1,2.2,3,4,5,6,7,8)
val y = #3 x
val _ = print (Int.toString y)
val _ = case Int.toString y of "3" => () | _ => raise Fail "ng"
(* 2013-10-02 ohori
realが奇数番目に現れるレコードでは，それ以降のアラインメントが狂うらしい．
  # val x = (1,2.2,0,3,0,4,0,5) : int * real * int * int * int * int * int * int
*)

(*
2013-11-21 katsu

Fixed by changeset b5810ec57685. 
*)
