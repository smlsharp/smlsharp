(*
duplicated constructor names in exception bind should be rejected.
(syntax restriction)

<ul>
  <li>the number of duplicated names
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  <li>
  <li>the number of bindings sharing a duplicated name
    <ul>
      <li>2</li>
      <li>3</li>
    </ul>
  <li>
  <li>kind of exception bind
    <ul>
      <li>both</li>
      <li>only exception definition</li>
      <li>only exception replication</li>
    </ul>
  <li>
</ul>
*)
exception e121a;
exception e121 = e121a and e121 of int;

exception e122 of int and e122 of string;

exception e123a and e123b;
exception e123 = e123a and e123 = e123b;

exception e132 of int and e132 of string and e132 of bool;

exception e2221 of int and e2222 of string and e2221 of bool and e2222 of char;
