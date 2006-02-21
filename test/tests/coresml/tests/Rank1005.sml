(*
"let" expression can be poly-typed in Rank-1 type system.
(SML type system does not allow poly-typed let.)

<ul>
  <li>the polytype body expression of the let
    <ul>
      <li>a polytype variable</li>
      <li>a polytype function abstraction</li>
      <li>a record containing a polytype field</li>
      <li>a polytype constructed expression</li>
      <li>a polytype let expression</li>
    </ul>
  </li>
  <li>the type of body of let contains a type variable 
     <ul>
       <li>no</li>
       <li>yes</li>
     </ul>
  </li>
</ul>
*)
fun id x = x;
datatype 'a dt = D | E of 'a;

val vPolyVar1 = let in id end;
val vPolyVar2 = let val x = (id, fn x => x) in x end;

val vPolyAbs1 = let in fn x => x end;
val vPolyAbs2 = let val f = fn x => x in fn x => f end;

val vRecord1 = let in {a = id} end;
val vRecord2 = let val x = (id, id) in {a = x, b = id} end;

val vPolyConst1 = let in D end;
val vPolyConst2 = let val x = D in E D end;

val vLet1 = let in let in id end end;
val vLet2 = let val x = (id, D) in let val y = (E id, x) in (x, y) end end;
