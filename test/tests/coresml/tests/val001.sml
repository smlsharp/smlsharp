(*
val declaration.
rule 15

<ul>
  <li>the number of type variables
    <ul>
      <li>0</li>
      <li>1</li>
      <li>2</li>
      <li>2, but one of them is not used in body</li>
    </ul>
  </li>
</ul>
 *)
val v1 = 1;

val 'x v2 = fn x => x : 'x;

val ('x, 'y) v3 = fn x => fn y => (x : 'x, y : 'y);

val ('x, 'y) v4 = fn x => fn y => (x : 'x, y);
