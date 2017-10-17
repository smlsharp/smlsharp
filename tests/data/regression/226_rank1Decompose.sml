val (x,y) = (fn () => (fn x => x, 1)) ();
val _ = x 1
val _ = x "a"
(* 2012-7-27 ohori:
Rank1 type inference does not work with val bind:
(interactive):3.1-3.47 Warning:
  (type inference 065) dummy type variable(s) are introduced due to value
  restriction in: y, x
val x = fn : ?X1 -> ?X1
val y = fn : ?X2 -> ?X2
*)

(* 2012-7-27 ohori:
Fixed by 4347:14fac70326b2
*)
