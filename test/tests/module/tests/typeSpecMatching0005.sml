(*
derived form of type specification:
<pre>
  type tyvarseq tycon = ty
</pre>

<ul>
  <li>type name in the type expression
    <ul>
      <li>globally defined type name</li>
      <li>type name specified in the same signature</li>
      <li>type name specified in an inner structure in the same signature</li>
    </ul>
  <li>
</ul>
*)
datatype dt = D;
signature S =
sig
  type t1 = dt
  type t2 = t1 * string
  structure S : sig type t end
  type t3 = S.t * string
  val x : t1 * t2 * t3
end;

structure S =
struct
  type t1 = dt
  type t2 = t1 * string
  structure S = struct type t = int end
  type t3 = S.t * string
  val x = (D, (D, "a"), (1, "b"))
end;

structure STrans = S : S;
val (xTrans1, xTrans2, xTrans3) = STrans.x;

structure SOpaque = S :> S;
val (xOpaque1, xOpaque2, xOpaque3) = SOpaque.x;
