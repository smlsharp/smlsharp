(*
matching of derived form include specification.

<pre>
  include sigid1 ... sigidN
</pre>
*)
signature SA = sig type t val x : t end;
signature SB = sig datatype dt = D val y : dt end;

signature S =
sig
  include SA SB
  val z : t * dt
end;

structure S = 
struct
  type t = int
  datatype dt = D
  val x = 1
  val y = D
  val z = (2, D)
end;

structure STrans = S : S;
structure SOpaque = S :> S;
