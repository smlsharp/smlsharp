datatype t = B
type u = t
val x = raise Fail "unimplemented"
val y = x

(*
2020-08-23 katsu

This causes an unexpected type error:

371_opqauetype.smi:4.4-4.4 Error:
  (type inference 088) type and type annotation don't agree
    inferred type: ?.t
  type annotation: t

*)
