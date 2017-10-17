_interface "043_type.smi"
structure S =
struct
  datatype option = datatype option
end

(*
2011-08-21 katsu

This causes unexpected name error.

043_type.smi:3.3-3.35 Error: Provide check fail (missing type name) : S.option

2011-08-22 ohori
Fixed.
*)
