(*
Entities defined in the body of abstype should hide type and data constructors
defined in abstype and withtype.

<ul>
  <li>check items
    <ul>
      <li>data constructor</li>
      <li>type constructor</li>
      <li>type name declared in "withtype"</li>
    </ul>
  </li>
</ul>
*)
datatype dt1 = D of int;
abstype at1 = D of string
with
datatype t1 = D of bool
val ax1 = D true
end;
val gx1 = D false;

datatype t2 = D of int;
abstype t2 = D of string
with
datatype t2 = E of real
val ax2 : t2 = E 1.23
end;
val gx2 : t2 = ax2;

datatype t3 = D of int;
abstype at3 = D of string
withtype t3 = string * at3
with
type t3 = bool * at3
val ax3 : at3 = D "c"
end;
val gx3 : t3 = (true, ax3);
