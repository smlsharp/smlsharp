_interface "106_functorexn.smi"
functor F (
  A : sig
    exception E
  end
) =
struct
  structure P = A
  exception E2 = P.E
end

(*
2011-09-04 katsu

This causes an unexpected type error.

106_functorexn.sml:2.9-10.3 Error:
  (type inference 063-1) type and type annotation don't agree
    inferred type: exn(t13[]) -> __exntag__(t13[]) * __exntag__(t13[])
  type annotation: exn(t13[]) -> {1: exn(t13[])}
*)

(*
2011-09-05 ohori

Fixed.
*)
