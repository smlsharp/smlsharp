(*
test cases for local declaration.
rule 21, 23, 24

<ul>
  <li>the number of local declarations
    <ul>
      <li>0</li>
      <li>1</li>
      <li>2</li>
      <li>2, separated by semicolon</li>
    </ul>
  </li>
</ul>
 *)

local
in
val v1 = 1
end;

local
  val x2 = 1
in
val v2 = x2
end;

local
  val x31 = true
  val x32 = "foo"
in
val v3 = (x31, x32)
end;

local
  val x41 = true;
  val x42 = "foo"
in
val v4 = (x41, x42)
end;

