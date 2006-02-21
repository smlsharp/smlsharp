(*
fn expression.
rule 12

<ul>
  <li>type of expression
    <ol>
      <li>monotype</li>
      <li>polytype</li>
    </ol>
  </li>
  <li>type of argument</li>
    <ol>
       <li>base type</li>
       <li>function type</li>
    </ol>
  </li>
  <li>type of result</li>
    <ol>
       <li>base type</li>
       <li>function type</li>
    </ol>
  </li>
</ul>
 *)
val v111 = fn x => x + 1;

val v112 = fn x => (fn y => x + y + 1);

val v121 = fn x => (x 1) + 1;

val v122 = fn x => fn y => (x 1) + y;

val v211 = fn x => (x, true);

val v212 = fn x => (fn y => (x, y));

val v221 = fn x => (x 1, true);

val v222 = fn x => fn y => (x 1, y);
