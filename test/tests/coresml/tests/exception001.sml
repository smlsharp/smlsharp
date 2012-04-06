(*
exception declaration.
rule 20, 30

<ul>
  <li>with parameter
    <ul>
      <li>no</li>
      <li>yes</li>
    </ul>
  </li>
</ul>
 *)
exception E1;
val v1 = E1;

exception E2 of int;
val v2 = E2 2;
