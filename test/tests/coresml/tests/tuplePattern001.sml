(*
tuple pattern.

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
fun f1 r = case r of (s, t) => (s, t, 1);
val v11 = f1 (1, 2);
val v12 = f1 ("foo", "bar");

fun f2 r = case r of ({x}, {y}) => (x, y);
val v2 = f2 ({x = 1}, {y = 2});

fun f3 r = case r of (s, t) => s + t;
val v3 = f3 (1, 2);

datatype 'a t4 = C4 of 'a;
fun f4 r = case r of (C4 s, C4 t) => (s, t);
val v4 = f4 (C4 1, C4 "foo");

fun f5 r = case r of (f, g) => (f 1, g 2);
val v5 = f5 (fn x => x + 1, fn x => x - 1);

fun f6 r x = case r of (f, g) => (f x, g x);
val v6 = f6 (fn x => x, fn x => (x, x));
