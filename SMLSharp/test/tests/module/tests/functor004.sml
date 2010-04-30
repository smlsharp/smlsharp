(*
"datatype" spec in functor parameter.
*)
functor F(S : sig datatype dt = D of int | E end) = 
struct datatype dt = D of S.dt val x = S.D 1 end;
structure P = struct datatype dt = D of int | E end;
structure S = F(P);
val x = S.x;
val y = case x of P.D n => n | P.E => ~1;
val a = S.D(P.D 1);
val b = case a of S.D(P.D n) => n| S.D(P.E) => ~1;
