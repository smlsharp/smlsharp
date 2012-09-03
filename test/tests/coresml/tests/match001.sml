(*
occurrence of variables in rule body which are bound in atomic pattern.
rule 14.

<ul>
  <li>pattern
    <ul>
      <li>constructor pattern</li>
      <li>variable pattern</li>
      <li>record pattern</li>
      <li>tuple pattern</li>
      <li>parenthetic pattern</li>
    </ul>
</ul>
 *)
datatype dt1 = C1;
fun f x = case x of C1 => 1;
val v1 = f C1;

fun f x = case x of y => y;
val v2 = f 2;

fun f x = case x of {a = y} => y;
val v3 = f {a = 3};

fun f x = case x of (y, w, z) => y;
val v4 = f (4, true, "foo");

fun f x = case x of (y) => y
val v5 = f 5;
