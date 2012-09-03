(*
name resolution of structure name in a functor body.

*)
functor F(P : sig datatype dt = D val x : int end) =
struct
  val x = (P.D, P.x)
  structure P = struct datatype dt = D val x = 2 end
  val y = (P.D, P.x)
end;
structure S = struct datatype dt = D val x = 1 end;
structure T = F(S);

val (x1, x2) = T.x;
val (y1, y2) = T.y;
val eq = x1 = y1;
