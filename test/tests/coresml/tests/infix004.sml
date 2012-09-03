(*
test infix fun declaration enclosed in parenthesis.
see p64 in SML Definition.

<ul>
  <li>infix id
    <ul>
      <li>non parnethetic, followed by "="</li>
      <li>non parnethetic, followed by ":ty"</li>
      <li>parnethetic, given two arguments</li>
      <li>parnethetic, given three arguments</li>
      <li>non parenthetic, but the left argument is
         parenthetic infix pattern</li>
    </ul>
  </li>
</ul>
 *)

infix ## %%;
datatype t = %% of int * int;

fun x ## y = x + y;
val v1 = 1 ## 2;

fun x ## y : int = x - y;
val v2 = 2 ## 3;

fun (x ## y) = x * y;
val v3 = 1 ## 2;

fun (x ## y) z = x + y + z;
val v4 = (2 ## 3) 4;

fun (x %% y) ## z = x + y + z;
val v5 = (3 %% 4) ## 5;
