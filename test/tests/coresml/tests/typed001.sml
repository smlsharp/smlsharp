(*
typed expression.
rule 9.

<ul>
  <li>inner expression
  <ul>
    <li>normal expression</li>
    <li>typed expression</li>
  </ul>
  </li>
</ul>
 *)
val v1 = 1 : int;

type t = int;
val v2 = ((1 : int) : t);

type t = int;
val v3 = ((1 : t) : int);
