(*
a record expression can contain a polymorphic field value in Rank1 type system.
And, selection of the field is also poly-typed.

<ul>
  <li>the poly-typed field expression
    <ul>
      <li>a polytype variable</li>
      <li>a polytype function abstraction</li>
      <li>a record containing a polytype field</li>
      <li>a polytype constructed expression</li>
    </ul>
  </li>
</ul>
*)
fun id x = x;
datatype 'a dt = D;

val rPolyVar = {a = id};
val xPolyVar = #a rPolyVar;

val rPolyAbs = {a = fn x => x};
val xPolyAbs = #a rPolyAbs;

val rRecord = {a = {a = id}};
val xRecord = #a rRecord;

val rPolyConst = {a = D};
val xPolyConst = #a rPolyConst;

