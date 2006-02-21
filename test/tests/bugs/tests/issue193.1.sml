structure S =
let
  structure T =
  struct
    datatype t1 = D
    datatype t2 = datatype t1 
  end
in 
  struct end
end;
