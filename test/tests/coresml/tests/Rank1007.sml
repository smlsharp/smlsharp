(*
"handle" expression must be a mono-type under the Rank-1 type system.

<ul>
  <li>type of body expression
    <ul>
      <li>poly-type</li>
      <li>mono-type</li>
    </ul>
  </li>
  <li>result expression of the barnch of handle
    <ul>
      <li>"raise" expression</li>
      <li>poly-type variable</li>
      <li>poly-type non-variable expression</li>
      <li>mono-type expression</li>
    </ul>
  </li>
</ul>
*)
fun id x = x;
fun inc x = x + 1;
exception E;

val fHanldePolyBodyRaise = id handle _ => raise E;
val xHanldePolyBodyRaise = fHanldePolyBodyRaise 1;

val fHanldePolyBodyPolyVar = id handle _ => id;
val xHanldePolyBodyPolyVar = fHanldePolyBodyPolyVar 2;

val fHanldePolyBodyPolyExp = id handle _ => (fn x => x);
val xHanldePolyBodyPolyExp = fHanldePolyBodyPolyExp 3;

val fHanldePolyBodyMonoExp = id handle _ => (fn x => x + 1);
val xHanldePolyBodyMonoExp = fHanldePolyBodyMonoExp 5;

(********************)

val fHanldeMonoBodyRaise = inc handle _ => raise E;
val xHanldeMonoBodyRaise = fHanldeMonoBodyRaise 1;

val fHanldeMonoBodyPolyVar = inc handle _ => id;
val xHanldeMonoBodyPolyVar = fHanldeMonoBodyPolyVar 2;

val fHanldeMonoBodyPolyExp = inc handle _ => (fn x => x);
val xHanldeMonoBodyPolyExp = fHanldeMonoBodyPolyExp 3;

val fHanldeMonoBodyMonoExp = inc handle _ => (fn x => x - 1);
val xHanldeMonoBodyMonoExp = fHanldeMonoBodyMonoExp 4;
