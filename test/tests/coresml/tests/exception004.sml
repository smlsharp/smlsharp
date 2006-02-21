(*
exception replications in a same declaration.
rule 20, 31

<ul>
  <li>replicated exception
    <ul>
      <li>defined</li>
      <li>replication</li>
      <li>replication of exception defined in the same decalration</li>
    </ul>
  </li>
</ul>
 *)

exception R1 of int;
exception E1 = R1;
val v1 = E1 1;

exception R2 of int;
exception R2 of bool and E2 = R2;
val v2 = E2 2;

exception R3 of int
exception E31 = R3
exception R3 of string and E31 = R3 and E32 = E31;
val v3 = E32 3;
