(*
list pattern (derived form).

<ul>
  <li>the number of elements
    <ul>
      <li>0</li>
      <li>1</li>
    </ul>
  </li>
</ul>
 *)
fun f1 l = case l of [] => 1 | _ => 2;
val v1 = f1 [];

fun f2 l = case l of [x] => x | _ => 2;
val v2 = f2 [1];

fun f3 l = case l of [x, y] => x + y | _ => 2;
val v3 = f3 [1 ,2];

fun f4 l = case l of [x, y, z] => x + y + z | _ => 2;
val v4 = f4 [1, 2, 3];
