(*
exception replication declaration.
rule 20, 31

<ul>
  <li>with parameter
    <ul>
      <li>no</li>
      <li>yes</li>
    </ul>
  </li>
</ul>
 *)
exception E;
exception E1 = E;
val v1 = E1;

exception E of int;
exception E2 = E;
val v2 = E2 2;
