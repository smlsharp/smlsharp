(*
andalso expression.

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

val v1 = 1 = 1 andalso false;

val v2 = 1 = 2 andalso raise E;
