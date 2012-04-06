(*
test cases for local declaration.
rule 21, 23, 24

<ul>
  <li>the number of global declarations
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
end;

local
in
val v2 = 2
end;

local
in
val v31 = 3
val v32 = "three"
end;

local
in
val v41 = 4;
val v42 = "four"
end;

