functor F(S : sig exception E of real end) =
struct 
  exception F = S.E 
  fun f r = raise S.E r 
end;

structure P = struct exception E of real end;
structure T = F(P);
val x = (T.f 1.23) handle T.F r => r;
