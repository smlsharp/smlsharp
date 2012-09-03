(*
long ID expression.

<ul>
  <li>expression
    <ul>
      <li>variable</li>
      <li>datatype constructor</li>
      <li>exception constructor</li>
    </ul>
  </li>
</ul>
*)
structure S1 = struct val x = 1 end;
val x1 = S1.x;

structure S2 = struct datatype dt = D end;
val x2 = S2.D;

structure S3 = struct exception E end;
val x3 = S3.E;
