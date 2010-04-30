(*
orelse expression.

<ul>
  <li>result of left argument
    <ul>
      <li>true</li>
      <li>false</li>
    </ul>
  </li>
</ul>
 *)
exception E;

val v1 = 1 = 1 orelse raise E;

val v2 = 1 = 2 orelse true;
