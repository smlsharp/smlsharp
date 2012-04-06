(*
application expression.
rule 8

<ul>
  <li>type of called function
    <ul>
      <li>monotype</li>
    </ul>
  </li>
  <li>function expression
    <ul>
      <li>global bound</li>
      <li>local bound</li>
      <li>function expression</li>
    </ul>
  </li>
</ul>
 *)

val f1 = fn x => x + 1;
val v1 = f1 1;

local
  val f2 = fn x => x + 1
in
val v2 = f2 1
end;

val v3 = (fn x => if x then 1 else 2) true;
