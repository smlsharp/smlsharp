(*
use of alias type defined by a type declaration.

<ul>
  <li>occurrence of alias type
    <ul>
      <li>datatype declaration</li>
      <li>type declaration</li>
      <li>exception declaration</li>
    </ul>
  </li>
</ul>
*)
type t1 = int;
datatype dt1 = D of t1;
val x1 = D 1;

type t21 = int;
type t22 = t21 * string;
val x2 : t22 = (2, "abc");

type t3 = string;
exception E3 of t3;
val x3 = E3 "xyz";
