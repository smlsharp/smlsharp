(*
pattern rows (derived form).

<ul>
  <li>type annotation with label
    <ul>
      <li>no</li>
      <li>yes</li>
    </ul>
  </li>
  <li>aliase with label
    <ul>
      <li>no</li>
      <li>yes</li>
    </ul>
  </li>
</ul>
 *)
fun f11 r = case r of {a} => a;
val v11 = f11 {a = 11};

fun f12 r = case r of {a as (x, y)} => (a, x, y);
val v12 = f12 {a = (1, 2)};

fun f21 r = case r of {a : int} => a;
val v21 = f21 {a = 21};

fun f22 r = case r of {a : int * int as (x, y)} => (a, x, y);
val v22 = f22 {a = (2, 2)};
