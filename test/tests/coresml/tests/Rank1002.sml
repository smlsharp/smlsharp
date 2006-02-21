(*
A variable bound in a case branch is mono-typed within the result expression
of the branch in Rank-1 type system.
(This differs to the original Rank-1 type system depicted in the paper.)
<ul>
  <li>the pattern in the case branch which binds a polytyped variable.
    <ul>
      <li>a variable pattern</li>
      <li>a argument of a constructed pattern</li>
      <li>a variable in a field in a record pattern</li>
    </ul>
  </li>
</ul>
*)

fun id x = x;
datatype 'a dt = D of 'a;

val vPolyVarPattern = case id of f => (f 1, f "abc");

val vPolyConstPattern = case D id of D f => (f 1, f "abc");

val vPolyRecord = case {a = id} of {a = f} => (f 1, f "abc");
