(*
occurrence of variables in rule body which are bound in non-atomic pattern.
rule 14, 41, 42, 43

<ul>
  <li>pattern containing a variable pattern
    <ul>
      <li>constructor applicatioin</li> 
      <li>typed</li>
      <li>aliased</li>
      <li>typed and aliased</li>
      <li>aliasing</li>
    </ul>
</ul>
 *)
datatype dt1 = C1 of int;
fun f x = case x of C1 y => y;
val v1 = f (C1 1);

fun f x = case x of (y : int) => y;
val v2 = f 2;

fun f x = case x of y as 3 => y;
val v3 = f 3;

fun f x = case x of y : int as 4 => y;
val v4 = f 4;

fun f x = case x of z as y => y;
val v5 = f 5;
