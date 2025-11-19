signature G =
sig
  datatype c = T
end
signature I =
sig
  structure e : G
  type b
  sharing type b = e.c
end
signature R =
sig
  structure e : G
  structure a : I
  sharing type e.c = a.e.c
end
functor F(structure a : I) : R =
struct
  structure a = a
  structure e = a.e
end

(*
2025-11-19 katsu

This causes Bug.

uncaught exception: Bug.Bug: SigCheck: non dty instance at src/compiler/compilePhases/nameevaluation/main/SigCheck.sml:18.15
*)
