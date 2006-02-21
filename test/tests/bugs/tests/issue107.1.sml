signature S2 =
sig
  type t1
  type t2
  sharing type t1 = t2
end;

structure S2Trans : S2 =
struct
  type t1 = int * int
  type t2 = int * bool
end;