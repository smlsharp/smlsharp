structure X = F()
val _ = (raise X.E1) handle X.E2 => ()

(*
2019-04-26 katsu

344_functor2.sml:
../doc/tests/344_functor2.smi:1.8-5.2 Error:
  (name evaluation
  "CP-720") Provide check fails (functor body signature mismatch): F

344_functor.sml:
uncaught exception: Bug.Bug: PolyTyElimination: analyzeExnCon: TPEXEXN at src/compiler/compilePhases/polytyelimination/main/PolyTyElimination.sml:17
*)
