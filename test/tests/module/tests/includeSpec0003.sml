(*
multiple nested "include" specification.

<ul>
  <li>the number of signature related
    <ul>
      <li>3</li>
    </ul>
  </li>
</ul>
*)
signature S31 =
sig 
  type t
  datatype dt = D of t
  val x : t * dt 
end;
signature S32 =
sig
  include S31
  val y : t * dt
end;
signature S33 =
sig
  include S32
  val z : dt * t
end;
