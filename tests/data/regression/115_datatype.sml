_interface "115_datatype.smi"
structure S :> sig
  type t
  val f : t -> t
end =
struct
  datatype t = X
  fun f X = X
end

(*
2011-09-05 katsu

This causes an unexpected type error.

115_datatype.smi:4.7-4.16 Error:
  (type inference 063-1) type and type annotation don't agree
    inferred type: t(t32[[opaque(rv1,t(t30[]))]])
                   -> t(t32[[opaque(rv1,t(t30[]))]])
  type annotation: t(t30[]) -> t(t30[])
*)

(*
2011-09-05 ohori

Fixed.
*)
