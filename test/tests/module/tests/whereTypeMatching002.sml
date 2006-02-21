(*
matching of "where type".
error case.

*)
signature S = 
sig
  type t1
  type t2
  type t3
end
    where type t1 = int
      and type t2 = string 
      and type t3 = bool;

structure S =
struct
  type t1 = int
  type t2 = string
  type t3 = real
end;

structure STrans = S : S;
structure SOpaque = S :> S;
