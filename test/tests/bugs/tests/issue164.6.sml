structure STR =
struct
  type t = int * int
  fun f (x : int) = (x, x);
end;

signature SIG =
sig
  type t
  val f : int -> t
end;

structure S :>
sig
  structure T1 : SIG
  structure T2 : SIG
  sharing type T1.t = T2.t
end =
struct
  structure T1 = STR
  structure T2 = STR
end;

structure STR1 = S.T1;
structure STR2 = S.T2;
