(*
empty spec in functor parameter.
*)
functor F(S : sig end) = struct val y = 1 end;
structure P = struct val x = 2 end;
structure S = F(P);
val x = S.y;
