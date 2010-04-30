(*
equality check of datatype used in expressions.

*)
datatype 'a dtNeq = DNeq | ENeq of 'a;
datatype ''a dtEq = DEq | EEq of ''a;

val eq11 = DNeq = DNeq;
val eq12 = DNeq = (DNeq : real dtNeq);

val eq21 = DEq = DEq;
val eq22 = DEq = (DEq : real dtEq);

val v1 = ENeq 1.23;
val v2 = EEq 1.23;

fun f1 x = ENeq x;
val x11 = f1 1.23;
fun f2 x = EEq x;
val x12 = f2 1.23;

fun g1 (x : ''a) = ENeq x;
val x21 = g1 1.23;
fun g2 (x : ''a) = EEq x;
val x22 = g2 1.23;

fun h1 (x : 'a) = ENeq x;
val x31 = h1 1.23;
fun h2 (x : 'a) = EEq x;
val x32 = h2 1.23;
