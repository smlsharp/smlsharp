(*
val declaration.
rule 15

<ul>
  <li>the number of valbinds
    <ul>
      <li>2</li>
    </ul>
  </li>
  <li>the number of type variables
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
  <li>dependencies between valbinds
    <ul>
      <li>yes</li>
    </ul>
  </li>
</ul>
 *)
val v11 = fn x => x + 1;
val 'x v11 = fn x : 'x => (x, 1) and v12 = fn x : 'x => (v11 2, x);

val v21 = fn x => x + 1;
val ('x, 'y) v21 = fn x : 'x => (x, 1) and v22 = fn x : 'y => (v21 2, x);
