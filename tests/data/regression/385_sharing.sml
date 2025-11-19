signature S =
sig
  datatype t2 = D
  type t1
  sharing type t1 = t2
  val x : int
end

functor F (A : S) : S =
struct
  open A
end

(*
2025-11-19 katsu

This causes bug.

uncaught exception: Bug.Bug: SigCheck: non dty instance at src/compiler/compilePhases/nameevaluation/main/SigCheck.sml:18.14(404)

*)
