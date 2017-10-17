_interface "053_typerep.smi"
structure S =
struct
  datatype t = FOO
end
datatype t = datatype S.t

(*
2011-08-23 katsu

This causes an unexpected name error.

053_typerep.smi:5.1-5.25 Error: (name evaluation 234t) duplicate type name:t
*)

(*
2011-08-23 ohori

Fixed by 2491:826816c31351
*)

