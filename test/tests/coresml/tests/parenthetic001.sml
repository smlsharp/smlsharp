(*
parenthetic expression.
rule 5

<ul>
  <li>inner expression
  <ul>
    <li>constant</li>
    <li>variable</li>
    <li>record</li>
    <li>let</li>
    <li>parenthetic expression</li>
  </ul>
  </li>
</ul>
 *)

val v1 = (1);

val x = true
val v2 = (x);

val v3 = ({});

val v4 = (let val x = 1 in x end);

val v5 = ( ((1, 2)) );
