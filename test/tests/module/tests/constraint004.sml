(*
type name in a signature is replaced by "where type".

<ul>
  <li>constraint
    <ul>
      <li>transparent</li>
      <li>opaque</li>
    </ul>
  </li>
</ul>
*)
datatype dt = D;
signature S = sig type t val x : t end;
structure S = struct datatype t = datatype dt val x  = D end;

structure STrans1 = S : S where type t = dt;
structure STrans2 = S : S where type t = dt;
val xTrans = STrans1.x = STrans2.x;

structure SOpaque1 = S :> S where type t = dt;
structure SOpaque2 = S :> S where type t = dt;
val xOpaque = SOpaque1.x = SOpaque2.x;

