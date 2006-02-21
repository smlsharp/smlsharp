(*
matching of datatype specification.

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
signature S =
sig
  datatype dt0 = D0
  datatype 'a dt1 = D1 of 'a
  datatype ('a, 'b) dt2 = D2 of 'a * 'b
end;

structure STrans : S =
struct
  datatype dt0 = D0
  datatype 'a dt1 = D1 of 'a
  datatype ('a, 'b) dt2 = D2 of 'a * 'b
end;
structure SOpaque :> S =
struct
  datatype dt0 = D0
  datatype 'a dt1 = D1 of 'a
  datatype ('a, 'b) dt2 = D2 of 'a * 'b
end;
