(*
long ID pattern.

<ul>
  <li>pattern.
    <ul>
      <li>constant datatype constructor</li>
      <li>constant exception constructor</li>
    </ul>
  </li>
  <li>the numebr of argument patterns
    <ul>
      <li>0</li>
      <li>1</li>
    </ul>
  </li>
</ul>
*)
structure S11 = struct datatype dt = D end;
fun f11 x = case x of S11.D => 1;
val x11 = f11 S11.D;

structure S21 = struct exception E end;
fun f21 x = case x of S21.E => 2 | _ => 1;
val x21 = f21 S21.E;

structure S12 = struct datatype dt = D of int * int end;
fun f12 x = case x of S12.D(x, y) => x + y;
val x12 = f12 (S12.D(1, 2));

structure S22 = struct exception E of real * real end;
fun f22 x = case x of S22.E(x, y) => x + y | _ => 0.12;
val x22 = f22 (S22.E(1.23, 4.56));
