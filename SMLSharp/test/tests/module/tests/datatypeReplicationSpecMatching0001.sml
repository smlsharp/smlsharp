(*
matching of datatype replication specification.

<ul>
  <li>the number of parameter type variables
    <ul>
      <li>0</li>
      <li>1</li>
      <li>2</li>
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
datatype dt0 = D0 of int;
signature S0 =
sig
  datatype dt = datatype dt0
end;
structure S0Trans : S0 = 
struct
  datatype dt = datatype dt0
end;
structure S0Opaque :> S0 = 
struct
  datatype dt = datatype dt0
end;

datatype 'a dt1 = D1 of int * 'a;
signature S1 =
sig
  datatype dt = datatype dt1
end;
structure S1Trans : S1 = 
struct
  datatype dt = datatype dt1
end;
structure S1Opaque :> S1 = 
struct
  datatype dt = datatype dt1
end;

datatype ('a, 'b) dt2 = D2 of int * 'a * 'b;
signature S2 =
sig
  datatype dt = datatype dt2
end;
structure S2Trans : S2 = 
struct
  datatype dt = datatype dt2
end;
structure S2Opaque :> S2 = 
struct
  datatype dt = datatype dt2
end;
