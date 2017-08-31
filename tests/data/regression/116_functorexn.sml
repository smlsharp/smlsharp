_interface "116_functorexn.smi"
functor F (
  A : sig
    exception E
  end
) =
struct
  structure P = A
  exception E = P.E
  exception E2
end
(*
2011-09-05 katsu

This causes an unexpected type error.

116_functorexn.sml:2.9-11.3 Error:
  (type inference 063-1) type and type annotation don't agree
    inferred type: exnTag(t13[]) -> exnTag(t13[]) * exnTag(t13[])
  type annotation: exnTag(t13[]) -> {1: exnTag(t13[])}
*)

(*
2011-09-05 ohori

Fixed. This is due to not calling internalizeEnv against functor body
interfaceenv in CheckProvide.

*)
