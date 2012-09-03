signature S = sig datatype dt = E end;
structure S1 :> S = struct datatype dt = E end;
S1.E;
