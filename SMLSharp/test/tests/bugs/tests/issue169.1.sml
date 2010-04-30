functor F(S : sig datatype dt = D end) =
        struct datatype et = datatype S.dt end;

structure TAnonymous = F(datatype dt = D);

structure P = struct datatype dt = D end;
structure TNamed = F(P);
