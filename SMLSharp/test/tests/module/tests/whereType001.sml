(*
name resolution of "where type" sigExp.

The left side of "where type" is resolved in regard to the environment obtained
by the sigExp.
The right side of "where type" is resolved in regard to the outer environment.
*)
datatype dt = D;
datatype t = E;
signature S = sig type t datatype dt = F end where type t = dt;
