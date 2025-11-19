fun 'a f () = f ()

(*
2025-11-19 katsu
This must typecheck.

tests/data/regression/387_utvar.sml:1.1-18 Error:
  (type inference 074) User type variable cannot be generalized: 'a

*)
