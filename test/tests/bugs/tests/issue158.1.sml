signature SIG = sig type t val x : t end;
functor F(S : sig type t val x : t end) = 
struct datatype t = D of S.t val x = D(S.x) end :> SIG;

structure P = struct type t = real val x = 1.23 end;
structure T = F(P);

val a = T.x;
