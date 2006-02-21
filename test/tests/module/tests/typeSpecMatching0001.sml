(*
matching of type specification.
safe case.
<ul>
  <li>declaration in structure
    <ul>
      <li>type declaration</li>
      <li>datatype declaration</li>
    </ul>
  </li>
  <li>the number of parameter type variables
    <ul>
      <li>0</li>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
  <li>constraint
    <ul>
      <li>transparent</li>
      <li>opaque</li>
    </ul>
  </li>
</ul>
*)
signature S =
sig
  type t0
  type 'a t1
  type ('a, 'b) t2
end;

structure StypeTrans : S =
struct
  type t0 = int
  type 'a t1 = 'a * int
  type ('x, 'y) t2 = {a : 'x, b : 'y}
end;
structure StypeOpaque : S =
struct
  type t0 = int
  type 'a t1 = 'a * int
  type ('x, 'y) t2 = {a : 'x, b : 'y}
end;

structure SdatatypeTrans : S =
struct
  datatype t0 = D0
  datatype 'x t1 = D1 of 'x
  datatype ('x, 'y) t2 = D2 of 'x * 'y
end;
structure SdatatypeTrans :> S =
struct
  datatype t0 = D0
  datatype 'x t1 = D1 of 'x
  datatype ('x, 'y) t2 = D2 of 'x * 'y
end;
