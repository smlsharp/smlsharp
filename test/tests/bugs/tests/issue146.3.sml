signature S = sig type dt end;
structure P = struct type t = real end;
functor F(type t) : S = struct datatype dt = D of t end;
structure T = F(P);
