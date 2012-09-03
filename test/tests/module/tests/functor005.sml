(*
datatype replication spec in functor parameter.
*)
datatype gdt = D of int | E;
functor F(S : sig datatype dt = datatype gdt end) = 
struct datatype dt = D of S.dt val x = S.D 1 end;
structure P = struct datatype dt = datatype gdt end;
structure S = F(P);
val x = S.x;
val y = case x of D n => n | E => ~1;
val a = S.D(D 1);
val b = case a of S.D(D n) => n | S.D E => ~1;
