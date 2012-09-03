(*
datatype replication.
rule 18

<ul>
  <li>replicated datatype
    <ul>
      <li>global</li>
      <li>local</li>
    </ul>
  </li>
</ul>
 *)

datatype t = C1 of int;
datatype t1 = datatype t;
val v1 : t1 = C1 1;

local
  datatype t = C2 of int
in
datatype t2 = datatype t
end;
val v2 : t2 = C2 2;
