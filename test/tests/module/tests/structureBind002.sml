(*
multiple binds in a structure declaration.

<ul>
  <li>Bound names are unique in a structure declaration.</li>
</ul>
<ul>
  <li>the reference relation between binds
    <ul>
      <li>A structure refers to another global strucutre of the same name with
        another structure in a same structure bind.</li>
      <li>A structure refers to another global strucutre of the same name with
        itself.</li>
    </ul>
  </li>
</ul>
*)
structure S11 = struct datatype dt = E end;
structure S11 = struct datatype dt = D val x = D end
      and S12 = struct datatype dt = datatype S11.dt val x = E end;
datatype dt11 = datatype S11.dt;
datatype dt22 = datatype S12.dt;
val x111 = S11.x;
val x112 = S12.x;
val x121 = S11.D;
val x122 = S12.E;

structure S21 = struct datatype dt = E end
      and S22 = struct datatype dt = F end;
structure S21 = struct datatype dt = datatype S21.dt val x = E end
      and S22 = struct datatype dt = datatype S22.dt val x = F end;
datatype dt21 = datatype S21.dt;
datatype dt22 = datatype S22.dt;
val x211 = S21.x;
val x212 = S22.x;
val x221 = S21.E;
val x222 = S22.F;

