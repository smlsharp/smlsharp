(*
fun declaration (derived form).

<ul>
  <li>the number of parameters
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
  <li>the number of rules
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
</ul>
 *)
fun f11 p1 = p1 + 1;

fun f12 1 = 0
  | f12 p1 = p1;

fun f21 p1 p2 = p1 + p2;

fun f22 1 p2 = 1 + p2
  | f22 p1 p2 = p1 + p2;
