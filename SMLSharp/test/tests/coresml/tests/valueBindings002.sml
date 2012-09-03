(*
value bindings
rule 25, 42, 43

<ul>
  <li>pattern containing a variable pattern
    <ul>
      <li>constructor application</li>
      <li>typed</li>
      <li>aliased</li>
      <li>typed and aliased</li>
      <li>aliasing</li>
    </ul>
</ul>
 *)
datatype dt1 = C1 of int;
val C1 v1 = C1 1;
val w1 = v1 + 1;

val v2 : int = 2;
val w2 = v2 + 2;

val v3 as 3 = 3;
val w3 = v3 + 3;

val v4 : int as 4 = 4;
val w4 = v4 + 4;

val v5 as y = 5;
val w5 = v5 + 5;
