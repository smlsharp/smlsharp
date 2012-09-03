(*
multiple nested "open" declaration

<ul>
  <li>the number of structures related
    <ul>
      <li>3</li>
    </ul>
  </li>
</ul>
*)
structure S31 = 
struct
  type t = int
  datatype dt = D of t
  val x = D 1
end;
structure S32 =
struct
  open S31
  datatype dt2 = E of dt * t
  val y = (x, 123)
end;
structure S33 =
struct
  open S32
  type t3 = dt * dt2 * t
  val z = (x, y, 123)
end;
