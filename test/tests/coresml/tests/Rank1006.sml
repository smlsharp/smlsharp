(*
domain of function can not be polymorphic.
The range of function is poly-type.
Poly-type argument must be instantiated to a mono-type before passed to the
function.
<ul>
  <li>polytype argument expression of function
    <ul>
      <li>a polytype variable</li>
      <li>a polytype function abstraction</li>
      <li>a record containing a polytype field</li>
      <li>a polytype constructed expression</li>
    </ul>
  </li>
  <li>the result type contains the type variable which is in the domain type.
    <ul>
      <li>no</li>
      <li>yes</li>
    </ul>
  </li>
</ul>
*)
fun id x = x;
datatype 'a dt = D;
(* 'a does not occur in the result type. *)
val f1 = fn (x : 'a) => fn y => y;
(* 'a occurs in the result type. *)
val f2 = fn (x : 'a) => fn y => (x, y);

val fPolyVar11 = f1 id;
val xPolyVar11 = fPolyVar11 1;
val fPolyVar12 = f2 id;
val xPolyVar12 = fPolyVar12 1;

val fPolyVar21 = fn x => (1, f1 x);
val xPolyVar21 = fPolyVar21 1;
val fPolyVar22 = fn x => (1, f2 x);
val xPolyVar22 = fPolyVar22 1;

val fPolyAbs11 = f1 (fn x => fn y => y);
val xPolyAbs11 = fPolyAbs11 1;
val fPolyAbs12 = f2 (fn x => fn y => y);
val xPolyAbs12 = fPolyAbs12 1;

val fPolyAbs21 = f1 (fn x => fn y => (x, y));
val xPolyAbs21 = fPolyAbs21 1;
val fPolyAbs22 = f2 (fn x => fn y => (x, y));
val xPolyAbs22 = fPolyAbs22 1;

val fRecord11 = f1 {a = id};
val xRecord11 = fRecord11 1;
val fRecord12 = f2 {a = id};
val xRecord12 = fRecord12 1;

val fRecord21 = fn x => f1 {a = id, b = x};
val xRecord21 = fRecord21 1 "a";
val fRecord22 = fn x => f2 {a = id, b = x};
val xRecord22 = fRecord22 1 "a";

val fPolyConst11 = fn x => f1 D;
val xPolyConst11 = fPolyConst11 1 "a";
val fPolyConst12 = fn x => f2 D;
val xPolyConst12 = fPolyConst12 1 "a";

val fPolyConst21 = fn x => f1 (D, x);
val xPolyConst21 = fPolyConst21 1 "a";
val fPolyConst22 = fn x => f2 (D, x);
val xPolyConst22 = fPolyConst22 1 "a";
