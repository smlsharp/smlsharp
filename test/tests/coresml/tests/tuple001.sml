(*
tuple expression.

<ul>
  <li>type of fields.
    <ul>
      <li>type variable</li>
      <li>record type</li>
      <li>base type</li>
      <li>applied type constructor</li>
      <li>mono function type</li>
      <li>poly function type</li>
    </ul>
  </li>
</ul>
 *)
fun f1 x = (x, x);
val v11 = f1 1;
val v12 = f1 "foo";

val v2 = ({x = 1}, {y = 2});

val v31 = (1, 2);
val v32 = ("foo", "bar");

datatype 'a t4 = C4 of 'a;
val v4 = (C4 1, C4 "foo");

val v5 = (fn x => x + 1, fn x => x - 1);

val v6 = (fn x => x, fn x => (x, x));
