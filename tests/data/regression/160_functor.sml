functor F(A : sig
  exception E
end) =
struct
  structure B = A
end

(*
2011-11-29 katsu

This should cause an provide check error since B.E of the body of F is a
replication of A.E of the argument of F but the interface does not say so.

*)

(*
2011-11-29 ohori

Since exception may be a replicate of a hidden local exception,
exception E in an interface should be matched against exception
replication. So this is accepted.

*)
