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
  <li>the number of bindings sharing the same type variable
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
</ul>
 *)
val 'x v111 = fn x : 'x => x and v112 = 1;
val 'x v121 = 2 and v122 = fn x : 'x => x;
val 'x v131 = fn x : 'x => x and v132 = fn x : 'x => x;

val ('x, 'y) v211 = fn x : 'x => x and v212 = fn x : 'y => x;
val ('x, 'y) v221 = fn x : 'x => x and v222 = fn x : 'x => x;
val ('x, 'y) v231 = fn x : 'y => x and v232 = fn x : 'y => x;
