(*
multiple binds in a signature declaration.

<ul>
  <li>Bound names are unique in a signature declaration.</li>
</ul>
<ul>
  <li>the reference relation between binds
    <ul>
      <li>A signature refers to a global strucutre of the same name with
        another signature in a same signature bind.</li>
      <li>A signature refers to a global strucutre of the same name with
        itself.</li>
    </ul>
  </li>
</ul>
*)
structure S11 = struct datatype dt = E end;
signature S11 = sig datatype dt = D val x : dt end
      and S12 = 
          sig datatype dt = datatype S11.dt val x : dt val y : S11.dt end;

structure S21 = struct datatype dt = E end
      and S22 = struct datatype dt = F end;
signature S21 =
          sig datatype dt = datatype S21.dt val x : dt val y : S21.dt end
      and S22 =
          sig datatype dt = datatype S22.dt val x : dt val y : S22.dt end;

