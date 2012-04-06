(*
binding by atomic pattern in value bindings with rec.
rule 26, 32, 35, 37

<ul>
  <li>pattern
    <ul>
      <li>variable pattern</li>
      <li>parenthic pattern</li>
      <li>wild pattern</li>
    </ul>
  </li>
</ul>
 *)

val rec v1 = fn x => if 0 = x then 1 else v1 (x - 1);
val w1 = v1 1;

val rec (v2) =  fn x => if 0 = x then 2 else v2 (x - 1);
val w2 = v2 2;

val rec _ = fn x => x;

