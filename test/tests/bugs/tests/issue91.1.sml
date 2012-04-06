local
  datatype t2 = C2 of int
in
datatype t2 = datatype t2
end;
val v2 : t2 = C2 2;
