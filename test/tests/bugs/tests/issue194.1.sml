signature T = sig end;
structure S1 : T =
struct
  datatype dt = D | E
  fun f D = ()
end;

structure S2 =
struct
  datatype dt = D | E
  fun f D = ()
end;
