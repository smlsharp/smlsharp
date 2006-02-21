(*
derived form of constrained structure binding.

<ul>
  <li>constraint
    <ul>
      <li>transparent</li>
      <li>opaque</li>
    </ul>
  </li>
</ul>
*)
signature S = sig type t datatype dt = D val x : t val y : dt end;
structure S = 
struct
  datatype dt = D
  type t = dt
  val x = D
  val y = D
end;
structure STrans : S = S;
datatype dtTrans = DTrans of STrans.t * STrans.dt;
val xTrans = STrans.x;
val yTrans = STrans.y;
val dtTrans = DTrans(xTrans, yTrans);

structure SOpaque :> S = S;
datatype dtOpaque = DOpaque of SOpaque.t * SOpaque.dt;
val xOpaque = SOpaque.x;
val yOpaque = SOpaque.y;
val dtOpaque = DOpaque(xOpaque, yOpaque);
