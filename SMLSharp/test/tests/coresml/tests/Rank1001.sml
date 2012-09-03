(*
result expression of case branch is mono-typed in Rank-1 type system.

<ul>
  <li>result expression of case branch
    <ul>
      <li>polymorphic typed variable bound at global</li>
      <li>polymorphic expression (non variable)</li>
      <li>polymorphic typed variable bound in a variable pattern of the
          branch</li>
      <li>polymorphic typed variable bound in a constructed pattern of the
          branch</li>
      <li>polymorphic typed variable bound in a record pattern of the
          branch</li>
    </ul>
  </li>
</ul>
*)

fun id x = x;
datatype 'a dt = D of 'a;

val vPolyGlobal = case 1 of _ => id;

val vPolyExp = case 1 of _ => (fn x => x);

val vPolyVarPattern = case id of f => f;

val vPolyConstPattern = case D id of D f => f;

val vPolyRecord = case {a = id} of {a = f} => f;
