fn x => fn y => (x y; x = x)
(* 2012-7-27 ohori: 
  This type error code is accepted:
val it = _ : [''a, 'b. (''a -> 'b) -> ''a -> bool]
*)

(* 2012-7-27 ohori.
Fixed by 4346:b56f9ded1731
*)
