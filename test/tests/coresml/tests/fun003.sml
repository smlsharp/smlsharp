(*
fun declration with type annotation

<ul>
  <li>the number of binds in the same declaration
    <ul>
      <li>1</li>
    </ul>
  </li>
  <li>the number of rules
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
  <li>type annotated rule
    <ul>
      <li>only the first</li>
      <li>only the second</li>
      <li>both of the first and the second</li>
    </ul>
  </li>
</ul>
*)
fun f1 x y : bool = x < y;
val v1 = f1 1 2;

fun f21 1 1 : bool = true
  | f21 x y = x < y;
val v21 = (f21 1 1, f21 2 3);

fun f22 1 1 = true
  | f22 x y : bool = x < y;
val v22 = (f22 1 1, f22 2 3);

fun f23 1 1 : bool = true
  | f23 x y : bool = x < y;
val v23 = (f23 1 1, f23 2 3);
