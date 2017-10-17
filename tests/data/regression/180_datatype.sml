datatype t1 = datatype t2

(*
2011-12-05 katsu

This does not cause any errors.
Should this cause a provide check error?
180_datatype.smi says that "t1" is a new type, but actually it is
a replica of "t2".

*)


(*
2011-12-05 ohori

This cannot be checked. Under the new semantics, interface
  datatype t1 = T
is a constraint that t1 is a datatype with a specified 
constructore set. So it matches datatype replication as well.

This is necessary to allow replication of locally defined type
such as:
local datatype bar = A in
  datatype foo = datatype bar
end
*)
