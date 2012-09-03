signature S =
sig
  val f : ('a -> 'a) -> string
end;
structure S =
struct
  fun f x = "a"
end;
fun g x = x
val x = S.f g;

structure S1 = S : S;
val y = S1.f g;
