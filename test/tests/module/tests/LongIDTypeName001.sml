(*
long ID type name.

<ul>
  <li>type constructor.
    <ul>
      <li>type constructor decalred by datatype</li>
      <li>type constructor decalred by type</li>
    </ul>
  </li>
  <li>the numebr of parameter types
    <ul>
      <li>0</li>
      <li>1</li>
    </ul>
  </li>
</ul>
*)
structure S11 = struct datatype dt = D end;
datatype dt11 = D11 of S11.dt;
val x11 = D11(S11.D);

structure S12 = struct datatype 'a dt = D of 'a end;
datatype dt12 = D12 of int S12.dt;
val x12 = D12(S12.D 12);

structure S21 = struct type t = int * real end;
datatype dt21 = D21 of S21.t;
val x21 = D21(1, 2.34);

structure S22 = struct type 'a t = int * real * 'a end;
datatype dt22 = D22 of (string * bool) S22.t;
val x22 = D22(1, 2.34, ("abc", true));
