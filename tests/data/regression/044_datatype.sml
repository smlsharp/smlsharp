_interface "044_datatype.smi"
structure S =
struct
  datatype t = T
  fun f T T = T
  val x = T : t
end

(*
2011-08-21 katsu

This causes unexpected name error.

044_datatype.smi:3.12-3.12 Error: Provide check fail (missing type name) : S
044_datatype.smi:4.11-4.11 Error: unbound type constructor or type alias: t
044_datatype.smi:4.16-4.16 Error: unbound type constructor or type alias: t


2011-08-22 ohori
Fixed.

*)

