(*
variable type expressions.
rule 44.

<ul>
  <li>type expression which the type variable is instantiated to.
    <ul>
       <li>base type</li>
       <li>applied type constructor</li>
       <li>type variable</li>
    </ul>
  </li>
</ul>
 *)
type 'a t1 = 'a;
val v1 : int t1 = 1;

type 'a t2 = 'a;
val v2 : (int t2) t2 = 2;

type 'a t3 = 'a t2;
val v3 : int t3 = 3;
