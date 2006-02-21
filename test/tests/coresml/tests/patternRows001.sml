(*
flexible pattern in pattern rows.
rule 38, 39

<ul>
  <li>the number of branches containing flexible record pattern
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
  <li>the number of fields matching with flexible pattern
    <ul>
      <li>0</li>
      <li>1</li>
    </ul>
  </li>
</ul>
 *)
fun f1 x = case x of {n1 = 1, n2, ...} => n2 | {n1, n2} => n2;
val v11 = f1 {n1 = 1, n2 = 2};
val v12 = f1 {n1 = 2, n2 = 3};

fun f2 x = case x of {n1 = 1, n2, ...} => n2 | {n1, n2, n3} => n2 + n3;
val v21 = f2 {n1 = 1, n2 = 2, n3 = 3};
val v22 = f2 {n1 = 2, n2 = 3, n3 = 4};
