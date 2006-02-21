datatype dt = D;
signature S1 = sig datatype dt = datatype dt end;
structure S1Trans : S1 = struct datatype dt = D end;
