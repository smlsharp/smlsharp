exception E;
signature S = sig val f : real -> real end;
functor F(S : sig end) : S =
struct fun f r = raise E end;

structure P = struct end;
structure T = F(P);
val x = (T.f 1.23) handle E => 0.0;
