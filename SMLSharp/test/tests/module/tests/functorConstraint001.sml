(*
functor constrained by a signature.

<ul>
  <li>specification in the constraining signature
    <ul>
      <li>val spec</li>
      <li>type spec</li>
      <li>eqtype spec</li>
      <li>datatype spec</li>
      <li>datatype replication spec</li>
      <li>exception spec</li>
      <li>structure spec</li>
    </ul>
  </li>
  <li>constraint
    <ul>
      <li>transparent</li>
      <li>opaque</li>
    </ul>
  </li>
</ul>
*)
signature SVal = 
sig
  val x : int
end;
structure PVal = struct val x = true end;

functor FValTrans(S : sig val x : bool end) = 
struct val x = "a" val x = 1 end : SVal;
structure SValTrans = FValTrans(PVal);
val xValTrans = SValTrans.x;

functor FValOpaque(S : sig val x : bool end) = 
struct val x = "a" val x = 1 end :> SVal;
structure SValOpaque = FValOpaque(PVal);
val xValOpaque = SValOpaque.x;
