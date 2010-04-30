(*
type declaration.
rule 16, 27

<ul>
  <li>the number of typbinds
    <ul>
      <li>2</li>
    </ul>
  </li>
  <li>dependency between typbinds
    <ul>
      <li>none</li>
      <li>yes, but refer to another type</li>
    </ul>
  </li>
</ul>
 *)
type t11 = int and t12 = bool;
val v1 : (t11 * t12) = (1, true);

type t21 = string;
type t21 = int and t22 = t21 * bool;
val v2 : (t21 * t22) = (1, ("foo", true));
