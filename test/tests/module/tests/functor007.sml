(*
"structure" spec in functor parameter.
*)
functor F(S : sig structure T : sig val x : int end end) =
struct val y = S.T.x + 1 end;
structure P = struct structure T = struct val x = 2 end end;
structure S = F(P);
val x = S.y;
