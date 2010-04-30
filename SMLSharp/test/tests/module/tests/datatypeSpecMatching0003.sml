(*
matching of datatype specification.
datatype with polymorphic constructors.

<ul>
  <li>type of data constructor in specification and definition
    <ul>
      <li>spec has polymorphic constructor, but def does not.</li>
      <li>def has polymorphic constructor, but spec does not.</li>
    </ul>
  </li>
  <li>signature constraint
    <ul>
      <li>transparent</li>
      <li>opaque</li>
    </ul>
  </li>
</ul>
*)
signature S1 = sig datatype 'a dt = D of 'a end;
structure S1Trans : S1 = struct datatype 'a dt = D of int end;
structure S1Opaque :> S1 = struct datatype 'a dt = D of int end;

signature S2 = sig datatype 'a dt = D of int end;
structure S2Trans : S2 = struct datatype 'a dt = D of 'a end;
structure S2Opaque :> S2 = struct datatype 'a dt = D of 'a end;
