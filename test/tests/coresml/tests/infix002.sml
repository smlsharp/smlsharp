(*
fun declaration using infix id with "op" modifier.

<ul>
  <li>parameters
    <ul>
      <li>a tuple</li>
      <li>a non-tuple</li>
      <li>two non-tuples</li>
      <li>three non-tuples</li>
    </ul>
  </li>
</ul>
 *)
infix 1 %%;

fun op %% (x, y) = x * y;
val v1 = 1 %% 2;

fun op %% x = x + 1;
val v2 = op %% 3;

fun op %% x y = x - y;
val v3 = op %% 2 3;

fun op %% x y z = x + y + z;
val v4 = op %% 1 2 3;
