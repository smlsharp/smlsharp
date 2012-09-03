(*
"eqtype" spec in functor parameter.
*)
functor F(S : sig eqtype t end) = 
struct datatype dt = D of S.t fun eq (x : S.t, y) = x = y end;
structure P = struct type t = int end;
structure S = F(P);
val x = S.eq(1, 2);
val y = S.eq(2, 2);
val a = S.D 1;
val b = case a of S.D n => n;
