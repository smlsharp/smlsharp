datatype t = * of int * int;
val (x * y) = (1 * 2);

(* '=' may not re-bound. 
datatype s = = of int * int;
val (op = (x, y)) = (op = (1, 2));
*)
