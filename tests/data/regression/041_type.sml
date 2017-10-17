_interface "041_type.smi"
structure G =
struct
  type 'a t = 'a array
end

(*
2011-08-21 katsu

This causes unexpected name error.

041_type.smi:3.8-3.24 Error: Provide check fail (missing type name) : G

2011-08-21 ohori
Fixed.

*)
