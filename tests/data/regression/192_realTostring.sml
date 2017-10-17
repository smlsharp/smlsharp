val x = print ("x = " ^ (Real.toString 1.0E~5) ^ "\n")
val y = print ("y = " ^ (Real.toString  (1.0E~5 * 100000.0)) ^ "\n")
val z = print ("z = " ^ (Real.toString 1.0E~4) ^ "\n")

(*
2012-1-2 ohori
According to the results
  x = ~1E~3
  y = ~1
  uncaught exception: Subscript
  アボートしました
Real.toString must be wrong; real arithmetics is probably OK.
*)

(*
2012-04-26 katsu

fixed by changeset 94e36def4822.
*)
