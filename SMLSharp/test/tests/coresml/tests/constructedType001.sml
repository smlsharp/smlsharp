(*
type construction.
rule 46

<ul>
  <li>the number of type parameters
    <ul>
      <li>0</li>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
</ul>
 *)
type t1 = bool;
val v1 : t1 = true;

type 'a t2 = 'a * bool;
val v2 : int t2 = (2, false);

type ('a, 'b) t3 = 'a * 'b * bool;
val v3 : (int, string) t3 = (3, "three", true);
