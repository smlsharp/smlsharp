(*
matching of "where type".

*)
signature S = 
sig
  type t1
  type t2
  type t3
  val x : t1 * t2 * t3
end
    where type t1 = int
      and type t2 = string 
      and type t3 = bool;

structure S =
struct
  type t1 = int
  type t2 = string
  type t3 = bool
  val x = (1, "a", true)
end;

structure STrans = S : S;
val (xTrans1, xTrans2, xTrans3) = STrans.x;

structure SOpaque = S :> S;
val (xOpaque1, xOpaque2, xOpaque3) = SOpaque.x;
