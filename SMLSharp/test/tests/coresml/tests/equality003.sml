(*
equality check for type variable occuring in expressions.

*)
fun f11 (x : 'a) = 1;
val x111 = f11 1.23;
val x112 = f11 (ref 1.23);
fun f12 (x : ''a) = 1;
val x121 = f12 1.23;
val x122 = f12 (ref 1.23);

fun idEq (x : ''a) = x;
fun g11 (x : 'a) = idEq x;
val x211 = g11 1;
val x212 = g11 1.23;
val x213 = g11 (ref 1.23);
fun g12 (x : ''a) = idEq x;
val x221 = g12 1;
val x222 = g12 1.23;
val x223 = g12 (ref 1.23);
