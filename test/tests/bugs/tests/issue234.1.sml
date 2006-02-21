signature SIG =
sig
  datatype dt = T of int
  type t
  sharing type t = dt
end;

structure STR =
struct
  datatype dt = T of int
  type t = dt
end;

functor FUN(STR : SIG)  =
struct
  type t = STR.dt
end;

structure S = FUN(STR);
