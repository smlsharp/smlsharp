(*
local declaration.
rule 21

<ul>
  <li>entity declared in local
    <ul>
      <li>val</li>
      <li>type</li>
      <li>datatype</li>
      <li>data constructor</li>
      <li>exception</li>
    </ul>
  </li>
</ul>
 *)

val x1 = 1;
local
  val x1 = true
in
  val v11 = if x1 then 1 else 2
end;
val v12 = x1 + 2;

type t2 = int;
local
  type t2 = bool
in
  val v21 = true : t2
end;
val v22 = 1 : t2;

datatype dt3 = C31 of int;
local
  datatype dt3 = C32 of bool
in
  val v31 = case (C32 true) : dt3 of C32 true => 1 | C32 false => 2
end;
val v32 = C31 3 : dt3;

datatype dt41 = C4 of int;
local
  datatype dt42 = C4 of bool
in
  val v41 = case C4 true of C4 true => 1 | C4 false => 2
end;
val v42 = C4 4;

exception E5 of int;
local
  exception E5 of bool
in
  val v51 = case E5 true of E5 true => 1 | E5 false => 2
end;
val v52 = E5 5;
