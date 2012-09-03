(*
precedence of overloaded primitive operators.

<ul>
  <li>operator(precedence)
    <ul>
      <li>div(7)</li>
      <li>mod(7)</li>
      <li>*(7)</li>
      <li>/(7)</li>
      <li>+(6)</li>
      <li>-(6)</li>
      <li>&lt;(4)</li>
      <li>&gt;(4)</li>
      <li>&lt;=(4)</li>
      <li>&gt;=(4)</li>
    </ul>
  </li>
</ul>
 *)
infix 8 P8 PR8;
infix 7 P7 PR7;
infix 6 P6 PR6;
infix 5 P5 PR5;
infix 4 P4 PR4;
infix 3 P3 PR3 PNB3;

fun x P8 y = (x + y) * 17;
fun x P7 y = (x + y) * 13;
fun x P6 y = (x + y) * 11;
fun x P5 y = (x + y) * 7;
fun x P4 y = (x + y) * 5;
fun x P3 y = (x + y) * 3;

fun x PR8 y = (x + y) * 1.7;
fun x PR7 y = (x + y) * 1.3;
fun x PR6 y = (x + y) * 1.1;
fun x PR5 y = (x + y) * 0.7;
fun x PR4 y = (x + y) * 0.5;
fun x PR3 y = (x + y) * 0.3;

fun x PNB3 y = if y then x * 3 else x * 5;

val (n1, n2, n3, n4) = (3, 5, 7, 11);
val (r1, r2, r3, r4) = (3.3, 5.5, 7.7, 11.11);

val div1 = n1 P6 n2 div n3 P8 n4;

val mod1 = n1 P6 n2 mod n3 P8 n4;

val mul1 = n1 P6 n2 * n3 P8 n4;

val divReal1 = r1 PR6 r2 / r3 PR8 r4;

val plus1 = n1 P5 n2 + n3 P7 n4;

val sub1 = n1 P5 n2 - n3 P7 n4;

val lt1 = n1 PNB3 n2 < n3 P5 n4;

val gt1 = n1 PNB3 n2 > n3 P5 n4;

val lteq1 = n1 PNB3 n2 <= n3 P5 n4;

val gteq1 = n1 PNB3 n2 >= n3 P5 n4;
