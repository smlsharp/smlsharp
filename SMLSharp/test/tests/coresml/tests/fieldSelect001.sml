(*
field selection expression.

<ul>
  <li>the operand expression
    <ul>
      <li>record expression</li>
      <li>tuple expression</li>
      <li>variable of record type</li>
      <li>variable of type variable of record kind</li>
      <li>other expression of record type</li>
      <li>other expression of type variable of record kind</li>
    </ul>
  </li>
</ul>
 *)
val v1 = #x {x = 1, y = 2};

val v2 = #2 (1, 2);

fun f3 (r : {x : int, y : int}) = #x r;
val v3 = f3 {x = 3, y = 3};

fun f4 r = #x r;
val v41 = f4 {x = 4, z = 5};
val v42 = f4 {a = "bar", x = "foo"};

fun f5 x = {x = x, y = x};
val v5 = #x (f5 5);

fun f61 r = (#x r; r);
fun f62 r = #x (f61 r);
val v6 = f62 {x = 6};
