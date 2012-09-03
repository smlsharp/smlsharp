(*
variable expression.
rule 2

<ul>
  <li>location where referred variable is defined.
  <ul>
    <li>global variable in the same compile unit</li>
    <li>global variable in the previous compile unit</li>
    <li>local variable</li>
  </ul>
  </li>
</ul>
 *)

val x = 1;
val v1 = x;

val x = true
val v2 = x;

let
val x = "a"
in
  x
end;
