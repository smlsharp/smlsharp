signature S =
sig
  val f : 'a -> 'a -> 'a
end;
structure S =
struct
  fun f x y = y
end;
val x = S.f 1 2;

structure S1 = S : S;
val y = S1.f 1 2;
