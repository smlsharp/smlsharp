signature S = sig datatype dt = D of int | E of string end;
structure S2Trans : S =
struct
  datatype dt = D of int
  fun E string = D string
end;
