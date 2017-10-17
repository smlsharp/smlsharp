(*
functor F (A : sig end) =
struct
  type t (= boxed)
  val f : t -> int
end
*)

infixr ::
functor F () =
struct
  type t = int list
  fun f nil = 0 | f (h::t) = h : int
end

(*
2011-11-28 katsu

This causes an unexpected type error.

150_functor.sml:2.9-6.3 Error:
  (type inference 063-7) type and type annotation don't agree
    inferred type: unit(t7[]) -> {1: int(t0[]) list(t15[]) -> int(t0[])}
  type annotation: unit(t7[]) -> {1: t(t30[]) -> int(t0[])}

*)


(*
2011-11-28 ohori

Fixed.

When provide cheking of a functor body, those types declaraed as
  type foo (= kind)
must be instantiated to actual types before generateing type constraint 
declarations.

*)
