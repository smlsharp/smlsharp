(*
matching of datatype replication specification.
datatype in the structure is not declared by datatype replication.

<ul>
  <li>datatype declaration in structure
    <ul>
      <li>new datatype of same name and same data constructors with spec</li>
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
datatype dt = D;
signature S1 =
sig
  datatype dt = datatype dt;
end;

structure S1Trans : S1 =
struct
  datatype dt = D
end;
structure S1Opaque :> S1 =
struct
  datatype dt = D
end;

signature S2 =
sig
  structure S : sig datatype dt = D end
  datatype dt = datatype S.dt
end;
structure S2Trans : S2 =
struct
  structure S = struct datatype dt = D end
  datatype dt = D 
end;
structure S2Opaque :> S2 =
struct
  structure S = struct datatype dt = D end
  datatype dt = D 
end;
