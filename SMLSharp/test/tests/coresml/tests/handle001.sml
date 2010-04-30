(*
handle expression.
rule 10

<ul>
  <li>exception to be caught
    <ul>
      <li>no exception is raised</li>
      <li>an exception raised and caught</li>
      <li>an exception raised but not caught</li>
    </ul>
  </li>
</ul>
 *)

val v1 = 1 handle e => 2;

exception E;
val v2 = (raise E) handle E => 3;

exception E1;
exception E2;
val v3 = ((raise E1) handle E2 => 3) handle E1 => 1;
