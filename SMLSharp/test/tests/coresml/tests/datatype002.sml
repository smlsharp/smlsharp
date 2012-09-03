(*
datatype declaration.
rule 17, 28

<ul>
  <li>the number of datbinds
    <ul>
      <li>2</li>
    </ul>
  </li>
  <li>dependency between datbinds
    <ul>
      <li>none</li>
      <li>yes</li>
    </ul>
  </li>
</ul>
 *)
datatype t11 = C11 of int and t12 = C12 of bool;
val v1 : (t11 * t12) = (C11 1, C12 true);

datatype t21 = C21 of int and t22 = C22 of t21 * bool;
val v2 : (t21 * t22) = (C21 1, C22 (C21 2, true));
