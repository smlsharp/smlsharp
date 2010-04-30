(*
val declaration.
rule 15

<ul>
  <li>the number of valbinds
    <ul>
      <li>2</li>
    </ul>
  </li>
  <li>dependency between valbinds
    <ul>
      <li>none</li>
      <li>yes, but refer to another binding out of the val</li>
    </ul>
  </li>
</ul>
 *)
val v11 = 1 and v12 = 2;

val v21 = 1;
val v21 = true and v22 = (v21 + 2, 1);
