(*
exception replication.
rule 20, 31

<ul>
  <li>replicated exception
    <ul>
      <li>global</li>
      <li>global in the same compile unit</li>
      <li>local</li>
    </ul>
  </li>
</ul>
 *)

exception E;
exception E1 = E;
val v1 = E1;

exception E
exception E2 = E;
val v2 = E2;

local
  exception E
in
exception E3 = E
end;
val v3 = E3;
