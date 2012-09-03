(*
multiple signature binds in a signature declaration.

<ul>
  <li>Bound names are unique in a signature declaration.</li>
  <li>No dependency between signatures.</li>
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
signature S1 = sig type t datatype dt = D val x : t * dt end;

signature S21 = sig type t datatype dt = D val x : t * dt end
      and S22 = sig type t datatype dt = D val x : t * dt end;

signature S31 = sig type t datatype dt = D val x : t * dt end
      and S32 = sig type t datatype dt = D val x : t * dt end
      and S33 = sig type t datatype dt = D val x : t * dt end;
