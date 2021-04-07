infixr ::
val rec f : 'a list -> int = fn [] => 0 | _ :: t => f t

(*
This causes Bug.

uncaught exception: Bug.Bug: EvalITy: free tvar:'a(tv129) at src/compiler/compilerIRs/idcalc/main/EvalIty.sml:14.14(258)

This bug was reported in Issue #10.
*)
