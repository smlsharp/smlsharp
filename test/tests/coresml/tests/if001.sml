(*
if expression.
 *
<ul>
  <li>result type
    <ul>
      <li>mono type</li>
      <li>poly type</li>
    </ul>
  </li>
</ul>
 *)
fun f1 x = if x then 1 else 2;
val v1 = (f1 true, f1 false);

exception E2 of int;
fun f2 x = if x then raise E2 1 else raise E2 2;
val v2 = ((f2 true) handle E2 n => n, (f2 false) handle E2 n => n);
