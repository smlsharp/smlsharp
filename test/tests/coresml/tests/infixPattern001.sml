(*
infix constructor pattern.

<ul>
  <li>position of constructor pattern.
    <ul>
      <li>infix position</li>
      <li>nonfix position with "op" modifier</li>
    </ul>
  </li>
</ul>
 *)
datatype t = ## of int * int;

infix 1 ##;

fun f1 x = case x of x ## y => x + y;
val v1 = f1 (1 ## 2);

fun f2 x = case x of op ## (x, y) => x + y;
val v2 = f2 (op ## (2, 3));
