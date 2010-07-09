signature SIG = sig type dt end;
structure T = struct datatype dt = D end :> SIG;
functor F(P : sig type dt end) = struct datatype dt2 = D of P.dt end;
structure TBasic = F(T);
