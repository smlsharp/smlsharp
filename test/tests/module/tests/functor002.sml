(*
"type" spec in functor parameter.
*)
functor F(S : sig type t end) = struct datatype dt = D of S.t end;
structure P = struct type t = real end;
structure S = F(P);
val x = S.D 1.23;
val y = case x of S.D n => n;
datatype dt = E of S.dt;
val z = E(S.D 2.34);

