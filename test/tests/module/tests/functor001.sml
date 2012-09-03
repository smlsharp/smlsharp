(*
"val" spec in functor parameter.
*)
functor F(S : sig val x : int end) = struct val y = S.x + 1 end;
structure P = struct val x = 2 end;
structure S = F(P);
val x = S.y;
