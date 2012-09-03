(*
multiple binds in a structure declaration.

<ul>
  <li>Bound names are unique in a structure declaration.</li>
  <li>No dependency between structures.</li>
</ul>
<ul>
  <li>the number of binds
    <ul>
      <li>1</li>
      <li>2</li>
      <li>3</li>
    </ul>
  </li>
</ul>
*)
structure S1 = struct datatype dt = D val x = D end;
datatype dt1 = datatype S1.dt;
val x11 = S1.x;
val x12 = S1.D;

structure S21 = struct datatype dt = D val x = D end
      and S22 = struct datatype dt = D val x = D end;
datatype dt21 = datatype S21.dt;
datatype dt22 = datatype S22.dt;
val x211 = S21.x;
val x212 = S22.x;
val x221 = S21.D;
val x222 = S22.D;

structure S31 = struct datatype dt = D val x = D end
      and S32 = struct datatype dt = D val x = D end
      and S33 = struct datatype dt = D val x = D end;
datatype dt31 = datatype S31.dt;
datatype dt32 = datatype S32.dt;
datatype dt33 = datatype S33.dt;
val x311 = S31.x;
val x312 = S32.x;
val x313 = S33.x;
val x321 = S31.D;
val x322 = S32.D;
val x323 = S33.D;

