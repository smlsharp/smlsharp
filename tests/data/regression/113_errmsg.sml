_interface "113_errmsg.smi"
structure S =
struct
  datatype t = X of int | Y
end

(*
2011-09-05 katsu

This causes a data constructor type mismatch error, but
error message says "unbound type constructor."

113_errmsg.smi:3.21-3.21 Error:
  (name evaluation Ty-040) unbound type constructor or type alias: t
*)


(*
2011-09-05 ohori

This has been fixed by some of the earlier fixes.
*)
