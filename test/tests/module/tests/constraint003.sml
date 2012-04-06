(*
typing of val bind is instantiated or not by constraint.

<ul>
  <li>specification of the type
    <ul>
      <li>type declaration</li>
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
signature S = sig val f : int -> int end;
structure S = struct val f = fn x => x end;

structure STrans = S : S;
val fTrans = STrans.f;
val xTrans = fTrans 1;

structure SOpaque = S :> S;
val fOpaque = SOpaque.f;
val xOpaque = fOpaque 1;
