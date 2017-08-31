structure StringCvt :> sig
  type cs
  val f : cs -> unit
end
=
struct
  type cs = int
  fun f (x:cs) = ()
end

(*
2011-08-22 katsu

This causes an unexpected type error.

050_sig.sml:2.11-10.3 Error:
  (type inference 012) type and type annotation don't agree
  inferred type: cs(t0) -> unit(t7)
  type annotation: cs(t29) -> unit(t7)
*)

(*
2011-08-23 ohori

Fixed by adding a case for opaque signature constraint.

It use to be compiled to ICTYPED with opaque type, which would 
not typecheck. So a new type constraint ICSIGTYPED is introduced
and for ICSIGTYPED(icexp, ty, loc), opaque tycon in ty is revealed 
to the original tycon in one-level.

*)
