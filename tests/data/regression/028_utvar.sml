fun f n = [n] : 'a list

(*
2011-08-17 katsu

There is no type error in the above code but compiler reports the following
type error.

028_utvar.sml:1.11-1.23 Error:
  (type inference 012) type and type annotation don't agree
  inferred type: 'f list(t14)
  type annotation: 'a('a(tv19)) list(t14)

2011-08-18 ohori
Fixed. roll back in lambda depth adjustment in Unify.

*)
