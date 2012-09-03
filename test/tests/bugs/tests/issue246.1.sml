type 'a reader = 'a -> 'a  option;

fun f (x:'a) = NONE : 'a option;
val x = f "aaa";
case x of NONE => 1 | SOME _ => 2; (* safe *)

val f = f: 'a reader;
val x = f "aaa";
case x of NONE => 1 | SOME _ => 2; (* error *)
