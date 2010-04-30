(*
"include" spec in functor parameter.
*)
signature T = sig val x : int end;
functor F(S : sig include T end) = struct val y = S.x + 1 end;
structure P = struct val x = 2 end;
structure S = F(P);
val x = S.y;
