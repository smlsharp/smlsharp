(*
scope of abstype.

<ul>
  <li>check items
    <ul>
      <li>data constructor is hidden.</li>
      <li>type constructor is visible.</li>
      <li>type name declared in "withtype" is visible.</li>
    </ul>
  </li>
</ul>
*)
datatype dt1 = D of int;
abstype at1 = D of string
with
val ax1 : at1 = D "a"
end;
val gx1 = D 1;

datatype t2 = D of int;
abstype t2 = D of string
with
val ax2 : t2 = D "b"
end;
val gx2 : t2 = ax2;

datatype t3 = D of int;
abstype at3 = D of string
withtype t3 = string * at3
with
val ax3 : at3 = D "c"
end;
val gx3 : t3 = ("c", ax3);
