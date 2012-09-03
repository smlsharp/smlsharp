(*
"exception" spec in functor parameter.
*)
functor F(S : sig exception E of int end) =
struct fun f t n = if t then raise S.E n else 0 end;
structure P = struct exception E of int end;
structure S = F(P);
val x1 = S.f true 1 handle P.E n => n;
val x2 = S.f false 1 handle P.E n => n;
