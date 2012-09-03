(*
test case for General structure.
*)
val refMonoUnboxed1 = ref 100;
val derefMonoUnboxed1 = General.! refMonoUnboxed1;
val refMonoBoxed1 = ref (1, 2);
val derefMonoBoxed1 = General.! refMonoBoxed1;
val refPoly1 = ref (fn x => x);
val derefPoly1 = General.! refPoly1;

val refMonoUnboxed2 = ref 200;
val x = General.:= (refMonoUnboxed2, 400);
val refMonoBoxed2 = ref (2, 3);
val x = General.:= (refMonoBoxed2, (4, 6));
val refPoly2 = ref (fn x => (0, x));
val x = General.:= (refPoly2, (fn x => (1, x)));

val f1 = fn x => x + 1;
val f2 = fn x => x * 100;
val comp1 = (General.o (f1, f2)) 2;

val beforeRef1 = ref 1;
val before1 =
    General.before
    (beforeRef1 := (!beforeRef1 + 1), beforeRef1 := (!beforeRef1 * 10));
val x = beforeRef1;

val ignore1 = General.ignore 1;
