(*
handling precedence of infix constructor pattern.

<ul>
  <li>precedence relation between left constructor and middle constructor
    <ul>
      <li>></li>
      <li>=</li>
      <li><</li>
    </ul>
  </li>
  <li>precedence relation between middle constructor and right constructor
    <ul>
      <li>></li>
      <li>=</li>
      <li><</li>
    </ul>
  </li>
  <li>infix direction of left constructor
    <ul>
      <li>left</li>
      <li>right</li>
    </ul>
  </li>
  <li>infix direction of middle constructor
    <ul>
      <li>left</li>
      <li>right</li>
    </ul>
  </li>
  <li>infix direction of right constructor
    <ul>
      <li>left</li>
      <li>right</li>
    </ul>
  </li>
</ul>
 *)
datatype t = >> of t * t
           | ## of t * t
           | << of t * t
           | N of int

(*****************************************************************************)
(* left > mid < right *)

infix 3 >>
infix 2 ##
infix 3 <<
val f11111 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v11111 = f11111 (op ## (op >> (N 1, N 2), op << (N 3, N 4)));

infix 3 >>
infix 2 ##
infixr 3 <<
val f11112 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v11112 = f11112 (op ## (op >> (N 1, N 2), op << (N 3, N 4)));


infix 3 >>
infixr 2 ##
infix 3 <<
val f11121 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v11121 = f11121 (op ## (op >> (N 1, N 2), op << (N 3, N 4)));


infix 3 >>
infixr 2 ##
infixr 3 <<
val f11122 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v11122 = f11121 (op ## (op >> (N 1, N 2), op << (N 3, N 4)));


infixr 3 >>
infix 2 ##
infix 3 <<
val f11211 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v11211 = f11211 (op ## (op >> (N 1, N 2), op << (N 3, N 4)));


infixr 3 >>
infix 2 ##
infixr 3 <<
val f11212 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v11212 = f11212 (op ## (op >> (N 1, N 2), op << (N 3, N 4)));


infixr 3 >>
infixr 2 ##
infix 3 <<
val f11221 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v11221 = f11221 (op ## (op >> (N 1, N 2), op << (N 3, N 4)));


infixr 3 >>
infixr 2 ##
infixr 3 <<
val f11222 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v11222 = f11222 (op ## (op >> (N 1, N 2), op << (N 3, N 4)));


(*****************************************)
(* left > mid = right *)

infix 3 >>
infix 2 ##
infix 2 <<
val f12111 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v12111 = f12111 (op << (op ## (op >> (N 1, N 2), N 3), N 4));


infix 3 >>
infix 2 ##
infixr 2 <<
val f12112 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v12112 = f12112 (op << (op ## (op >> (N 1, N 2), N 3), N 4));


infix 3 >>
infixr 2 ##
infix 2 <<
val f12121 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v12121 = f12121 (op << (op ## (op >> (N 1, N 2), N 3), N 4));


infix 3 >>
infixr 2 ##
infixr 2 <<
val f12122 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v12122 = f12122 (op ## (op >> (N 1, N 2), op << (N 3, N 4)));


infixr 3 >>
infix 2 ##
infix 2 <<
val f12211 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v12211 = f12211 (op << (op ## (op >> (N 1, N 2), N 3), N 4));


infixr 3 >>
infix 2 ##
infixr 2 <<
val f12212 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v12212 = f12212 (op << (op ## (op >> (N 1, N 2), N 3), N 4));


infixr 3 >>
infixr 2 ##
infix 2 <<
val f12221 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v12221 = f12221 (op << (op ## (op >> (N 1, N 2), N 3), N 4));


infixr 3 >>
infixr 2 ##
infixr 2 <<
val f12222 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v12222 = f12222 (op ## (op >> (N 1, N 2), op << (N 3, N 4)));


(*****************************************)
(* left > mid > right *)

infix 3 >>
infix 2 ##
infix 1 <<
val f13111 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v13111 = f13111 (op << (op ## (op >> (N 1, N 2), N 3), N 4));


infix 3 >>
infix 2 ##
infixr 1 <<
val f13112 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v13112 = f13112 (op << (op ## (op >> (N 1, N 2), N 3), N 4));


infix 3 >>
infixr 2 ##
infix 1 <<
val f13121 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v13121 = f13121 (op << (op ## (op >> (N 1, N 2), N 3), N 4));


infix 3 >>
infixr 2 ##
infixr 1 <<
val f13122 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v13122 = f13122 (op << (op ## (op >> (N 1, N 2), N 3), N 4));


infixr 3 >>
infix 2 ##
infix 1 <<
val f13211 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v13211 = f13211 (op << (op ## (op >> (N 1, N 2), N 3), N 4));


infixr 3 >>
infix 2 ##
infixr 1 <<
val f13212 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v13212 = f13212 (op << (op ## (op >> (N 1, N 2), N 3), N 4));


infixr 3 >>
infixr 2 ##
infix 1 <<
val f13221 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v13221 = f13221 (op << (op ## (op >> (N 1, N 2), N 3), N 4));


infixr 3 >>
infixr 2 ##
infixr 1 <<
val f13222 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v13222 = f13222 (op << (op ## (op >> (N 1, N 2), N 3), N 4));


(*****************************************************************************)
(* left = mid < right *)

infix 2 >>
infix 2 ##
infix 3 <<
val f21111 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v21111 = f21111 (op ## (op >> (N 1, N 2), op << (N 3, N 4)));


infix 2 >>
infix 2 ##
infixr 3 <<
val f21112 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v21112 = f21112 (op ## (op >> (N 1, N 2), op << (N 3, N 4)));


infix 2 >>
infixr 2 ##
infix 3 <<
val f21121 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v21121 = f21121 (op ## (op >> (N 1, N 2), op << (N 3, N 4)));


infix 2 >>
infixr 2 ##
infixr 3 <<
val f21122 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v21122 = f21122 (op ## (op >> (N 1, N 2), op << (N 3, N 4)));


infixr 2 >>
infix 2 ##
infix 3 <<
val f21211 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v21211 = f21211 (op ## (op >> (N 1, N 2), op << (N 3, N 4)));


infixr 2 >>
infix 2 ##
infixr 3 <<
val f21212 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v21212 = f21212 (op ## (op >> (N 1, N 2), op << (N 3, N 4)));


infixr 2 >>
infixr 2 ##
infix 3 <<
val f21221 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v21221 = f21221 (op >> (N 1, op ## (N 2, op << (N 3, N 4))));


infixr 2 >>
infixr 2 ##
infixr 3 <<
val f21222 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v21222 = f21222 (op >> (N 1, op ## (N 2, op << (N 3, N 4))));


(*****************************************)
(* left = mid = right *)

infix 2 >>
infix 2 ##
infix 2 <<
val f22111 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v22111 = f22111 (op << (op ## (op >> (N 1, N 2), N 3), N 4));


infix 2 >>
infix 2 ##
infixr 2 <<
val f22112 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v22112 = f22112 (op << (op ## (op >> (N 1, N 2), N 3), N 4));


infix 2 >>
infixr 2 ##
infix 2 <<
val f22121 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v22121 = f22121 (op << (op ## (op >> (N 1, N 2), N 3), N 4));


infix 2 >>
infixr 2 ##
infixr 2 <<
val f22122 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v22122 = f22122 (op ## (op >> (N 1, N 2), op << (N 3, N 4)));


infixr 2 >>
infix 2 ##
infix 2 <<
val f22211 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v22211 = f22211 (op << (op ## (op >> (N 1, N 2), N 3), N 4));


infixr 2 >>
infix 2 ##
infixr 2 <<
val f22212 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v22212 = f22212 (op << (op ## (op >> (N 1, N 2), N 3), N 4));


infixr 2 >>
infixr 2 ##
infix 2 <<
val f22221 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v22221 = f22221 (op << (op >> (N 1, op ## (N 2, N 3)), N 4));


infixr 2 >>
infixr 2 ##
infixr 2 <<
val f22222 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v22222 = f22222 (op >> (N 1, op ## (N 2, op << (N 3, N 4))));


(*****************************************)
(* left = mid > right *)

infix 2 >>
infix 2 ##
infix 1 <<
val f23111 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v23111 = f23111 (op << (op ## (op >> (N 1, N 2), N 3), N 4));


infix 2 >>
infix 2 ##
infixr 1 <<
val f23112 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v23112 = f23112 (op << (op ## (op >> (N 1, N 2), N 3), N 4));


infix 2 >>
infixr 2 ##
infix 1 <<
val f23121 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v23121 = f23121 (op << (op ## (op >> (N 1, N 2), N 3), N 4));


infix 2 >>
infixr 2 ##
infixr 1 <<
val f23122 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v23122 = f23122 (op << (op ## (op >> (N 1, N 2), N 3), N 4));


infixr 2 >>
infix 2 ##
infix 1 <<
val f23211 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v23211 = f23211 (op << (op ## (op >> (N 1, N 2), N 3), N 4));


infixr 2 >>
infix 2 ##
infixr 1 <<
val f23212 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v23212 = f23212 (op << (op ## (op >> (N 1, N 2), N 3), N 4));


infixr 2 >>
infixr 2 ##
infix 1 <<
val f23221 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v23221 = f22221 (op << (op >> (N 1, op ## (N 2, N 3)), N 4));


infixr 2 >>
infixr 2 ##
infixr 1 <<
val f23222 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v23222 = f23222 (op << (op >> (N 1, op ## (N 2, N 3)), N 4));


(*****************************************************************************)
(* left < mid < right *)

infix 1 >>
infix 2 ##
infix 3 <<
val f31111 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v31111 = f31111 (op >> (N 1, op ## (N 2, op << (N 3, N 4))));


infix 1 >>
infix 2 ##
infixr 3 <<
val f31112 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v31112 = f31112 (op >> (N 1, op ## (N 2, op << (N 3, N 4))));


infix 1 >>
infixr 2 ##
infix 3 <<
val f31121 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v31121 = f31121 (op >> (N 1, op ## (N 2, op << (N 3, N 4))));


infix 1 >>
infixr 2 ##
infixr 3 <<
val f31122 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v31122 = f31122 (op >> (N 1, op ## (N 2, op << (N 3, N 4))));


infixr 1 >>
infix 2 ##
infix 3 <<
val f31211 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v31211 = f31211 (op >> (N 1, op ## (N 2, op << (N 3, N 4))));


infixr 1 >>
infix 2 ##
infixr 3 <<
val f31212 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v31212 = f31212 (op >> (N 1, op ## (N 2, op << (N 3, N 4))));


infixr 1 >>
infixr 2 ##
infix 3 <<
val f31221 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v31221 = f31221 (op >> (N 1, op ## (N 2, op << (N 3, N 4))));


infixr 1 >>
infixr 2 ##
infixr 3 <<
val f31222 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v31222 = f31222 (op >> (N 1, op ## (N 2, op << (N 3, N 4))));


(*****************************************)
(* left < mid = right *)

infix 1 >>
infix 2 ##
infix 2 <<
val f32111 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v32111 = f32111 (op >> (N 1, op << (op ## (N 2, N 3), N 4)));


infix 1 >>
infix 2 ##
infixr 2 <<
val f32112 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v32112 = f32112 (op >> (N 1, op << (op ## (N 2, N 3), N 4)));


infix 1 >>
infixr 2 ##
infix 2 <<
val f32121 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v32121 = f32121 (op >> (N 1, op << (op ## (N 2, N 3), N 4)));


infix 1 >>
infixr 2 ##
infixr 2 <<
val f32122 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v32122 = f32122 (op >> (N 1, op ## (N 2, op << (N 3, N 4))));


infixr 1 >>
infix 2 ##
infix 2 <<
val f32211 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v32211 = f32211 (op >> (N 1, op << (op ## (N 2, N 3), N 4)));


infixr 1 >>
infix 2 ##
infixr 2 <<
val f32212 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v32212 = f32212 (op >> (N 1, op << (op ## (N 2, N 3), N 4)));


infixr 1 >>
infixr 2 ##
infix 2 <<
val f32221 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v32221 = f32221 (op >> (N 1, op << (op ## (N 2, N 3), N 4)));


infixr 1 >>
infixr 2 ##
infixr 2 <<
val f32222 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v32222 = f32222 (op >> (N 1, op ## (N 2, op << (N 3, N 4))));


(*****************************************)
(* left < mid > right *)

infix 1 >>
infix 2 ##
infix 1 <<
val f33111 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v33111 = f33111 (op << (op >> (N 1, op ## (N 2, N 3)), N 4));


infix 1 >>
infix 2 ##
infixr 1 <<
val f33112 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v33112 = f33112 (op << (op >> (N 1, op ## (N 2, N 3)), N 4));


infix 1 >>
infixr 2 ##
infix 1 <<
val f33121 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v33121 = f33121 (op << (op >> (N 1, op ## (N 2, N 3)), N 4));


infix 1 >>
infixr 2 ##
infixr 1 <<
val f33122 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v33122 = f33122 (op << (op >> (N 1, op ## (N 2, N 3)), N 4));


infixr 1 >>
infix 2 ##
infix 1 <<
val f33211 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v33211 = f33211 (op << (op >> (N 1, op ## (N 2, N 3)), N 4));


infixr 1 >>
infix 2 ##
infixr 1 <<
val f33212 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v33212 = f33212 (op >> (N 1, op << (op ## (N 2, N 3), N 4)));


infixr 1 >>
infixr 2 ##
infix 1 <<
val f33221 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v33221 = f33221 (op << (op >> (N 1, op ## (N 2, N 3)), N 4));


infixr 1 >>
infixr 2 ##
infixr 1 <<
val f33222 = fn x => case x of x1 >> x2 ## x3 << x4 => (x1, x2, x3, x4);
val v33222 = f33222 (op >> (N 1, op << (op ## (N 2, N 3), N 4)));

