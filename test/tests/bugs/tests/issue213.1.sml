fun f x = 1;

structure STR1 = struct fun f a = a + 1.2 end;
structure STR2 : sig end = struct open STR1 end;

open STR2;
val x = f 1;
