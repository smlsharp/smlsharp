structure DatatypeDeclOpaque =
struct
  datatype dt = D
end :> sig
  datatype dt = D
end;
val xSDatatypeDeclOpaque = DatatypeDeclOpaque.D;

(*
2012-07-12 fukasawa

This causes BUG at constraint
if datatype decl in opaque signature.

Compiler bug:extractDatatypeTyCon: not a datatype
*)

(*
2012-07-15 ohori
Fixed by 4311:36a3d67739e5.
This is due to the case missing in DatatypeCompilation.
tyCon is a datatype if dtykind is either 
DTY or OPAQUE.
*)
