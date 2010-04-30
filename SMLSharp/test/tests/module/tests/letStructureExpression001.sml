(*
let structure expression.

<ul>
  <li>
    <ul>
      <li></li>
    </ul>
  </li>
</ul>
*)
structure S1 = 
let structure S11 = struct datatype dt = D end in S11 end;
val x1 : S1.dt = S1.D;

structure S2 = 
let structure S2 = struct datatype dt = D end in S2 end;
val x2 : S2.dt = S2.D;
