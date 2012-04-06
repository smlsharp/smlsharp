functor F(P : sig end) =
struct structure S = struct datatype dt = D end end;
structure Q = F(struct end);
