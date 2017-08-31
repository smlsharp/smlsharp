functor F (A : sig
 type 'a t
 val f : 'a t -> 'a
end) =
struct
end

structure S = F (
  datatype 'a t = T of 'a
  fun f (T x) = x
)

(*
2011-08-24 katsu

This causes an unexpected type error.

062_functorPoly.sml:8.15-11.1 Error:
  (type inference 007) operator and operand don't agree
  operator domain: ({} -> {}) * ['a. 'a t(t34) -> 'a]
  operand: ({} -> {}) * ('l t(t34) -> 'l)
*)


(*
2011-08-25 ohori

Here we have polymorphic parameter of known type.
I have added code to deal with this in InferType.
But this may not be expected in static analysus.

Unification fails (3)
t31 t(t36)
tag(t37)
F(4) {A.foo(t0)} {_tagof(A.foo(t0)), _sizeof(A.foo(t0))}
  (fn id(9) : {1: A.foo(t0)} => id(9), 'X.f(7))
[BUG] StaticAnalysis:unification fail(3)
    raised at: ../staticanalysis/main/StaticAnalysis.sml:206.31-206.56
   handled at: ../toplevel2/main/Top.sml:868.37
		main/SimpleMain.sml:359.53

Fixed by introduceing
* ICFNM1_POLY for abstracting over polymorphic types
* ICFAPPM_NOUNIFY
    for applying explicitly typed poly type arguments.
    Function term is not restricted to variable, since
    functor application will generate code of the form
      (F id) {x1,x2,...}
    where is (F id) is monomorphic and unifying application
    and the others are non unifying application.

*)
