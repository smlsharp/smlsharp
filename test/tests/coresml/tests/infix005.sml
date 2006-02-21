(*
handling precedence of infix ids.

<ul>
  <li>precedence relation between left operator and middle operator
    <ul>
      <li>></li>
      <li>=</li>
      <li><</li>
    </ul>
  </li>
  <li>precedence relation between middle operator and right operator
    <ul>
      <li>></li>
      <li>=</li>
      <li><</li>
    </ul>
  </li>
  <li>infix direction of left operator
    <ul>
      <li>left</li>
      <li>right</li>
    </ul>
  </li>
  <li>infix direction of middle operator
    <ul>
      <li>left</li>
      <li>right</li>
    </ul>
  </li>
  <li>infix direction of right operator
    <ul>
      <li>left</li>
      <li>right</li>
    </ul>
  </li>
</ul>
 *)
fun >> (x, y) = x + y;
fun ## (x, y) = x * y;
fun << (x, y) = x - y;

val (x1, x2, x3, x4) = (2, 3, 5, 7);

(*****************************************************************************)
(* left > mid < right *)

infix 3 >>
infix 2 ##
infix 3 <<
val v11111 = x1 >> x2 ## x3 << x4;

infix 3 >>
infix 2 ##
infixr 3 <<
val v11112 = x1 >> x2 ## x3 << x4;

infix 3 >>
infixr 2 ##
infix 3 <<
val v11121 = x1 >> x2 ## x3 << x4;

infix 3 >>
infixr 2 ##
infixr 3 <<
val v11122 = x1 >> x2 ## x3 << x4;

infixr 3 >>
infix 2 ##
infix 3 <<
val v11211 = x1 >> x2 ## x3 << x4;

infixr 3 >>
infix 2 ##
infixr 3 <<
val v11212 = x1 >> x2 ## x3 << x4;

infixr 3 >>
infixr 2 ##
infix 3 <<
val v11221 = x1 >> x2 ## x3 << x4;

infixr 3 >>
infixr 2 ##
infixr 3 <<
val v11222 = x1 >> x2 ## x3 << x4;

(*****************************************)
(* left > mid = right *)

infix 3 >>
infix 2 ##
infix 2 <<
val v12111 = x1 >> x2 ## x3 << x4;

infix 3 >>
infix 2 ##
infixr 2 <<
val v12112 = x1 >> x2 ## x3 << x4;

infix 3 >>
infixr 2 ##
infix 2 <<
val v12121 = x1 >> x2 ## x3 << x4;

infix 3 >>
infixr 2 ##
infixr 2 <<
val v12122 = x1 >> x2 ## x3 << x4;

infixr 3 >>
infix 2 ##
infix 2 <<
val v12211 = x1 >> x2 ## x3 << x4;

infixr 3 >>
infix 2 ##
infixr 2 <<
val v12212 = x1 >> x2 ## x3 << x4;

infixr 3 >>
infixr 2 ##
infix 2 <<
val v12221 = x1 >> x2 ## x3 << x4;

infixr 3 >>
infixr 2 ##
infixr 2 <<
val v12222 = x1 >> x2 ## x3 << x4;

(*****************************************)
(* left > mid > right *)

infix 3 >>
infix 2 ##
infix 1 <<
val v13111 = x1 >> x2 ## x3 << x4;

infix 3 >>
infix 2 ##
infixr 1 <<
val v13112 = x1 >> x2 ## x3 << x4;

infix 3 >>
infixr 2 ##
infix 1 <<
val v13121 = x1 >> x2 ## x3 << x4;

infix 3 >>
infixr 2 ##
infixr 1 <<
val v13122 = x1 >> x2 ## x3 << x4;

infixr 3 >>
infix 2 ##
infix 1 <<
val v13211 = x1 >> x2 ## x3 << x4;

infixr 3 >>
infix 2 ##
infixr 1 <<
val v13212 = x1 >> x2 ## x3 << x4;

infixr 3 >>
infixr 2 ##
infix 1 <<
val v13221 = x1 >> x2 ## x3 << x4;

infixr 3 >>
infixr 2 ##
infixr 1 <<
val v13222 = x1 >> x2 ## x3 << x4;

(*****************************************************************************)
(* left = mid < right *)

infix 2 >>
infix 2 ##
infix 3 <<
val v21111 = x1 >> x2 ## x3 << x4;

infix 2 >>
infix 2 ##
infixr 3 <<
val v21112 = x1 >> x2 ## x3 << x4;

infix 2 >>
infixr 2 ##
infix 3 <<
val v21121 = x1 >> x2 ## x3 << x4;

infix 2 >>
infixr 2 ##
infixr 3 <<
val v21122 = x1 >> x2 ## x3 << x4;

infixr 2 >>
infix 2 ##
infix 3 <<
val v21211 = x1 >> x2 ## x3 << x4;

infixr 2 >>
infix 2 ##
infixr 3 <<
val v21212 = x1 >> x2 ## x3 << x4;

infixr 2 >>
infixr 2 ##
infix 3 <<
val v21221 = x1 >> x2 ## x3 << x4;

infixr 2 >>
infixr 2 ##
infixr 3 <<
val v21222 = x1 >> x2 ## x3 << x4;

(*****************************************)
(* left = mid = right *)

infix 2 >>
infix 2 ##
infix 2 <<
val v22111 = x1 >> x2 ## x3 << x4;

infix 2 >>
infix 2 ##
infixr 2 <<
val v22112 = x1 >> x2 ## x3 << x4;

infix 2 >>
infixr 2 ##
infix 2 <<
val v22121 = x1 >> x2 ## x3 << x4;

infix 2 >>
infixr 2 ##
infixr 2 <<
val v22122 = x1 >> x2 ## x3 << x4;

infixr 2 >>
infix 2 ##
infix 2 <<
val v22211 = x1 >> x2 ## x3 << x4;

infixr 2 >>
infix 2 ##
infixr 2 <<
val v22212 = x1 >> x2 ## x3 << x4;

infixr 2 >>
infixr 2 ##
infix 2 <<
val v22221 = x1 >> x2 ## x3 << x4;

infixr 2 >>
infixr 2 ##
infixr 2 <<
val v22222 = x1 >> x2 ## x3 << x4;

(*****************************************)
(* left = mid > right *)

infix 2 >>
infix 2 ##
infix 1 <<
val v23111 = x1 >> x2 ## x3 << x4;

infix 2 >>
infix 2 ##
infixr 1 <<
val v23112 = x1 >> x2 ## x3 << x4;

infix 2 >>
infixr 2 ##
infix 1 <<
val v23121 = x1 >> x2 ## x3 << x4;

infix 2 >>
infixr 2 ##
infixr 1 <<
val v23122 = x1 >> x2 ## x3 << x4;

infixr 2 >>
infix 2 ##
infix 1 <<
val v23211 = x1 >> x2 ## x3 << x4;

infixr 2 >>
infix 2 ##
infixr 1 <<
val v23212 = x1 >> x2 ## x3 << x4;

infixr 2 >>
infixr 2 ##
infix 1 <<
val v23221 = x1 >> x2 ## x3 << x4;

infixr 2 >>
infixr 2 ##
infixr 1 <<
val v23222 = x1 >> x2 ## x3 << x4;

(*****************************************************************************)
(* left < mid < right *)

infix 1 >>
infix 2 ##
infix 3 <<
val v31111 = x1 >> x2 ## x3 << x4;

infix 1 >>
infix 2 ##
infixr 3 <<
val v31112 = x1 >> x2 ## x3 << x4;

infix 1 >>
infixr 2 ##
infix 3 <<
val v31121 = x1 >> x2 ## x3 << x4;

infix 1 >>
infixr 2 ##
infixr 3 <<
val v31122 = x1 >> x2 ## x3 << x4;

infixr 1 >>
infix 2 ##
infix 3 <<
val v31211 = x1 >> x2 ## x3 << x4;

infixr 1 >>
infix 2 ##
infixr 3 <<
val v31212 = x1 >> x2 ## x3 << x4;

infixr 1 >>
infixr 2 ##
infix 3 <<
val v31221 = x1 >> x2 ## x3 << x4;

infixr 1 >>
infixr 2 ##
infixr 3 <<
val v31222 = x1 >> x2 ## x3 << x4;

(*****************************************)
(* left < mid = right *)

infix 1 >>
infix 2 ##
infix 2 <<
val v32111 = x1 >> x2 ## x3 << x4;

infix 1 >>
infix 2 ##
infixr 2 <<
val v32112 = x1 >> x2 ## x3 << x4;

infix 1 >>
infixr 2 ##
infix 2 <<
val v32121 = x1 >> x2 ## x3 << x4;

infix 1 >>
infixr 2 ##
infixr 2 <<
val v32122 = x1 >> x2 ## x3 << x4;

infixr 1 >>
infix 2 ##
infix 2 <<
val v32211 = x1 >> x2 ## x3 << x4;

infixr 1 >>
infix 2 ##
infixr 2 <<
val v32212 = x1 >> x2 ## x3 << x4;

infixr 1 >>
infixr 2 ##
infix 2 <<
val v32221 = x1 >> x2 ## x3 << x4;

infixr 1 >>
infixr 2 ##
infixr 2 <<
val v32222 = x1 >> x2 ## x3 << x4;

(*****************************************)
(* left < mid > right *)

infix 1 >>
infix 2 ##
infix 1 <<
val v33111 = x1 >> x2 ## x3 << x4;

infix 1 >>
infix 2 ##
infixr 1 <<
val v33112 = x1 >> x2 ## x3 << x4;

infix 1 >>
infixr 2 ##
infix 1 <<
val v33121 = x1 >> x2 ## x3 << x4;

infix 1 >>
infixr 2 ##
infixr 1 <<
val v33122 = x1 >> x2 ## x3 << x4;

infixr 1 >>
infix 2 ##
infix 1 <<
val v33211 = x1 >> x2 ## x3 << x4;

infixr 1 >>
infix 2 ##
infixr 1 <<
val v33212 = x1 >> x2 ## x3 << x4;

infixr 1 >>
infixr 2 ##
infix 1 <<
val v33221 = x1 >> x2 ## x3 << x4;

infixr 1 >>
infixr 2 ##
infixr 1 <<
val v33222 = x1 >> x2 ## x3 << x4;
