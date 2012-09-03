functor F(P : sig type dt val x : dt end) =
struct datatype dt = D of P.dt val x = D(P.x) end;
signature SIG = sig type dt val x : dt end;
structure T = struct datatype dt = D val x = D end :> SIG;
structure TBasic = F(T);
