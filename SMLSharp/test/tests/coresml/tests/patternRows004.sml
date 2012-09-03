(*
flexible record patterns whose type is a record kinded type variable.
rule 38, 39

<ul>
  <li>the number of branches containing flexible record pattern
    <ul>
      <li>2</li>
    </ul>
  </li>
  <li>where the type variable is bound
    <ul>
      <li>inner most poly function</li>
      <li>inner most multiple recursive poly function</li>
      <li>outer poly function</li>
      <li>outer multiple recursive poly function</li>
    </ul>
  </li>
</ul>
 *)
fun f1 x = case x of {n1 = 1, n2, ...} => n2 | {n2, n3, ...} => n3;
val v11 = f1 {n1 = 1, n2 = 3, n3 = 5};
val v12 = f1 {n1 = 2, n2 = 7, n3 = 11};

fun f21 x = case x of {n1 = 1, n2, ...} => n2 + (f22 x) | {n2, n3, ...} => n3
and f22 x = case x of {n1 = 1, n2, ...} => n2 | {n2, n3, ...} => n3 + (f21 x)
val v21 = f21 {n1 = 1, n2 = 3, n3 = 5};
val v22 = f21 {n1 = 2, n2 = 7, n3 = 11};

fun f3 x =
    let fun f31 y = case x of {n1 = 1, n2, ...} => n2 | {n2, n3, ...} => n3
    in f31 end
val v31 = f3 {n1 = 1, n2 = 3, n3 = 5} true;
val v32 = f3 {n1 = 2, n2 = 7, n3 = 11} "a";

fun f41 x =
    let
      fun f411 y =
          case x of {n1 = 1, n2, ...} => n2 + (f42 x y) | {n2, n3, ...} => n3
    in f411 end
and f42 x =
    let
      fun f421 y =
          case x of {n1 = 1, n2, ...} => n2 | {n2, n3, ...} => n3 + (f41 x y)
    in f421 end
val v41 = f41 {n1 = 1, n2 = 3, n3 = 5} true;
val v42 = f41 {n1 = 2, n2 = 7, n3 = 11} "a";
