(*
binding by atomic pattern in value bindings.
rule 25, 32, 33, 34, 35, 36, 37

<ul>
  <li>pattern
    <ul>
      <li>wild pattern</li>
      <li>constant pattern</li>
      <li>constructor pattern</li>
      <li>variable pattern</li>
      <li>record pattern</li>
      <li>tuple pattern</li>
      <li>parenthic pattern</li>
    </ul>
  </li>
</ul>
 *)

val _ = 1;

val 2 = 2;

datatype dt3 = C3
val C3 = C3;

val v4 = 4;
val w4 = v4 + 4;

val {x = v5, y} = {x = 5, y = "five"};
val w5 = v5 + 5;

val (v6, y) = (6, "six");
val w6 = v6 + 6;

val (v7) = 7;
val w7 = v7 + 7;
