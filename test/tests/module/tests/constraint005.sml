(*
representation of type name in a signature is not replaced by "where type".

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

structure STrans = S : S where type t = dt;
val xTrans = STrans.D;

structure SOpaque = S :> S where type t = dt;
val xOpaque = SOpaque.D;

