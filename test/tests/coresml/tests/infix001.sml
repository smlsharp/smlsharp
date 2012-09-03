(*
parse of infix fun declaration

<ul>
  <li>the number of rules
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
  <li>use "op"
    <ul>
      <li>no</li>
      <li>yes</li>
    </ul>
  </li>
</ul>
 *)

infix 0 %%;

fun x %% y = x - y;
val v11 = 1 %% 2;
fun op %% (x, y) = x + y;
val v12 = 1 %% 2;

fun 1 %% 2 = 2 | x %% y = x + y;
val v21 = (1 %% 2, 2 %% 3);

fun 1 %% 2 = 221 | op %% (x, y) = x + y;
val v221 = (1 %% 2, 2 %% 3);
fun op %% (1, 2) = 222 | x %% y = x - y;
val v222 = (1 %% 2, 2 %% 3);
fun op %% (1, 2) = 223 | op %% (x, y) = x * y;
val v223 = (1 %% 2, 2 %% 3);
