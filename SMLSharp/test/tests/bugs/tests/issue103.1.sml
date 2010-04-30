signature S = sig datatype dt = D of int | E of string end;
structure S1Trans : S =
struct datatype dt = D of int | E of string | F of bool end;
