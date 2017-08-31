fun f (x, y:'a) = y

(*
2011-08-17 katsu

There is no type error in the above code but compiler reports the following
type errors.

/Users/katsu/smlsharp-ng/doc/tests/029_utvar.sml:1.11-1.14 Error:
  (type inference 048) type and type annotation don't agree
  inferred type: 'c
  type annotation: 'a('a(tv19))
/Users/katsu/smlsharp-ng/doc/tests/029_utvar.sml:1.1-1.19 Error:
  (type inference 057) User type variable cannot be generalized: 'a

2011-08-18 ohori
Fixed. roll back in lambda depth adjustment in Unify.
(Same as 028_utvar.sml

*)
