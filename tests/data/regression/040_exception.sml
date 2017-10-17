_interface "040_exception.smi"
structure G =
struct
  exception E
end

(*
2011-08-21 katsu

This causes unexpected name error.

040_exception.smi:3.13-3.13 Error: Provide check fail (missing id) : G.E

2011-08-22 ohori
Fixed. Corrected the treatment of path in CheckProvide.sml; rewote this module.

*)
