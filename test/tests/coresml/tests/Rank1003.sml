(*
range of function can be polymorphic, and result of application also.

<ul>
  <li>polytype body expression of function
    <ul>
      <li>a polytype variable</li>
      <li>a polytype function abstraction</li>
      <li>a record containing a polytype field</li>
      <li>a polytype constructed expression</li>
    </ul>
  </li>
  <li>the type of body contains the type variable which is bound by the
    abstraction.
    <ul>
      <li>no</li>
      <li>yes</li>
    </ul>
  </li>
</ul>
*)
fun id x = x;
datatype 'a dt = D;

val fPolyVar1 = fn x => id;
val xPolyVar1 = fPolyVar1 (1, 2);

val fPolyVar2 = fn x => (id, x);
val xPolyVar2 = fPolyVar2 (1, 2);

val fPolyAbs1 = fn x => fn y => y;
val xPolyAbs1 = fPolyAbs1 (1, 2);

val fPolyAbs2 = fn x => fn y => (x, y);
val xPolyAbs2 = fPolyAbs2 (1, 2);

val fRecord1 = fn x => {a = id};
val xRecord1 = fRecord1 (1, 2);

val fRecord2 = fn x => {a = id, b = x};
val xRecord2 = fRecord2 (1, 2);

val fPolyConst1 = fn x => D;
val xPolyConst1 = fPolyConst1 (1, 2);

val fPolyConst2 = fn x => (D, x);
val xPolyConst2 = fPolyConst2 (1, 2);
