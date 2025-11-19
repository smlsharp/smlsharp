fun 'a f () = (nil : 'a list; f ())

(*
2025-11-19 katsu
This must typecheck.

tests/data/regression/388_utvar.sml:1.1-35 Error:
  (type inference 073) User type variable cannot be generalized: 'a

*)
