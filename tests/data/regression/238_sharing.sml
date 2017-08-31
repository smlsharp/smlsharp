functor F (A : sig
  datatype t1 = D
  type t2
  sharing type t1 = t2
end) =
struct
  type t = A.t2
end

(*
2012-09-19 katsu

This causes BUG.

[BUG] NameEval (FunctorUtils): FUN_DTY in spec

*)
