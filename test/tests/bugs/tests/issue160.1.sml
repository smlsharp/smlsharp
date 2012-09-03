functor F(P : sig type dt val x : dt end) =
          struct datatype dt = D of P.dt val x = D(P.x) end;
signature SIG = sig type dt val x : dt end;
structure S = struct datatype dt = D val x = D end;

structure TTrans = F(S : SIG);
val xTrans = TTrans.x;

structure TOpaque = F(S :> SIG);
val xOpaque = TOpaque.x;
