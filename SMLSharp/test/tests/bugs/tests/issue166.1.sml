signature PSIG = sig type t val x : t end;
functor F(P : PSIG) = struct datatype dt = E of P.t val y = E(P.x) end;
structure S = struct datatype t = D val x = D end;
structure TOpaque = F(S :> PSIG);
TOpaque.y;
