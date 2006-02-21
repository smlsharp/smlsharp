(*
equal operator for ref type.

<ul>
  <li>type of contents
    <ul>
      <li>eq base type (int)</li>
      <li>noneq base type (real)</li>
      <li>eq constructed type</li>
      <li>noneq constructed type</li>
    </ul>
  </li>
</ul>
 *)

local
  val r1 = ref 0
  val r2 = ref 0
in
val ref11 = r1 = r1;
val ref12 = r1 = r2;
val ref13 = (r1 := 1; r1 = r1);
end;

local
  val r1 = ref 1.23
  val r2 = ref 1.23
in
val ref21 = r1 = r1;
val ref22 = r1 = r2;
val ref23 = (r1 := 3.21; r1 = r1);
end;

local
  datatype t = D1 | D2
  val r1 = ref D1
  val r2 = ref D1
in
val ref31 = r1 = r1;
val ref32 = r1 = r2;
val ref33 = (r1 := D2; r1 = r1);
end;

local
  datatype t = D1 | D2 | D3 of real
  val r1 = ref D1
  val r2 = ref D1
in
val ref41 = r1 = r1;
val ref42 = r1 = r2;
val ref43 = (r1 := D2; r1 = r1);
end;

