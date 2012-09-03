signature T = sig end;
structure S : T =
struct
  datatype dt = D | E
  fun f D = ()
end;
