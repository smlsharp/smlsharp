(*
flexible pattern in pattern rows.
rule 38, 39

<ul>
  <li>the number of branches containing flexible record pattern
    <ul>
      <li>2</li>
    </ul>
  </li>
  <li>flexible pattern overlap
    <ul>
      <li>R1 and R2 do not overlap</li>
      <li>R1 and R2 overlap</li>
      <li>R1 is subset of R2</li>
    </ul>
  </li>
</ul>
 *)
fun f1 x = case x of {n1 = 1, n2, ...} => n2 | {n3, n4, ...} => n3;
val v11 = f1 {n1 = 1, n2 = 2, n3 = 3, n4 = 4};
val v12 = f1 {n1 = 2, n2 = 3, n3 = 3, n4 = 4};

fun f2 x = case x of {n1 = 1, n2, ...} => n2 | {n2, n3, ...} => n2;
val v21 = f2 {n1 = 1, n2 = 2, n3 = 3};
val v22 = f2 {n1 = 2, n2 = 3, n3 = 3};

fun f3 x = case x of {n1 = 1, n2, ...} => n2 | {n1, n2, n3, ...} => n3;
val v31 = f3 {n1 = 1, n2 = 2, n3 = 3};
val v32 = f3 {n1 = 2, n2 = 3, n3 = 3};
