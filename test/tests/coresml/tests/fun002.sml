(*
fun declaration (derived form).

<ul>
  <li>the number of binds in the same declaration
    <ul>
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
fun f11 x y = x + f12 y
and f12 y = if y = 0 then 1 else f11 y (y - 1);
val v1 = (f11 1 2, f12 2);

fun f21 1 1 = 2
  | f21 x y = x + f22 y
and f22 1 = 1
  | f22 y = if y = 0 then 1 else f21 y (y - 1);
val v2 = (f21 1 2, f22 2);
