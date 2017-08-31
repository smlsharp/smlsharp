structure A =
struct
  fun f x = x
end
structure B : sig val f : 'a -> 'a end = A;

(*

2011-8-13 ohori.
This code causes type error (should bot be).

  fun A.f(v0)  x(v1) = x(v1)
  val B.f(v2) = B.f(v0) :['a(tv19). 'a(tv19) -> 'a(tv19)]
  valrecopimization done
  013_sig.sml:5.11-5.42 Error:
    (type inference 012) type and type annotation don't agree
    inferred type: 'b -> 'b
    type annotation: ['a. 'a -> 'a]

This is an error due to not treating bound tvars in user annotation specially.
Added error code e.g. (type inference 012) in typeinference.sml

Added rigid unification for user type variables in typeinference.sml and 
Unify.sml.

*)
