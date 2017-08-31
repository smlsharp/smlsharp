structure S :> sig
  datatype t = X
  val f : t -> unit
  val y : t
end =
struct
  datatype t = X
  fun f (x:t) = ()
  val y = X
end

(*
2011-08-27 katsu

This causes an unexpected type error.

077_sig.sml:1.11-8.3 Error:
  (type inference 012) signature mismatch at S.f
    inferred type: S.t(t34[]) -> unit(t7[])
  type annotation: t(t36[]) -> unit(t7[])
*)

(*
2011-08-27 ohori

Fixed by setting a proper OPAQUE dtyKind for the case of TSTR_DTY
in makeOpaqueInstanceTstr.

*)

