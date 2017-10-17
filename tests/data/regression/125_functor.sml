_interface "125_functor.smi"
(*
  functor F (
 A : sig
   type t
  end
  ) =
  struct
    datatype s = X of A.t
    val f : s -> A.t
  end
*)
functor F (
 A : sig
   type t
 end
) =
struct
  datatype s = X of A.t
  fun f (X x) = x
end

(*
2011-09-06 katsu

This causes an unexpected type error.

125_functor.sml:3.9-11.3 Error:
  (type inference 063-2) type and type annotation don't agree
    inferred type: ({1: 'E('RIGID(tv32))} -> {1: 'E('RIGID(tv32))})
                   -> {1: {FREEBTV(31)}s(t33[]) -> 'E('RIGID(tv32))}
  type annotation: ({1: 'E('RIGID(tv32))} -> {1: 'E('RIGID(tv32))})
                   -> {1: {FREEBTV(32)}s(t35[]) -> 'E('RIGID(tv32))}
*)

(*
2011-09-06 ohori

Fixed.
Functor body environment equivalence check (on spec vs real) 
in CheckProvide must be done under the equivalence relations
(1) on the corresponding newly introduce typIds,
(2) IDCON{id=id1, ty=ty1} = IDCON{id=id1, ty=ty1} iff
    ty1 equiv ty2
(3) IDEXVR _ = IDVAR _ (always)

*)
