_interface "051_typealias.smi"
structure Char =
struct
  type char = char
  type string = string
end

(*
2011-08-22 katsu

This causes unexpected name error.

051_typealias.smi:2.1-5.3 Error: (name evaluation 052) duplicate type name:char
*)

(*
2011-08-23 ohori

Fixed by suppressing the name duplication check in making an effective env
(evalEnv) in CheckProvide.sml
*)


