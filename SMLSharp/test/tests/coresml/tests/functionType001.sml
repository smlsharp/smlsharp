(*
function type.
rule 47

<ul>
  <li>argument type</li>
    <ul>
      <li>mono type</li>
      <li>poly type</li>
    </ul>
  <li>result type</li>
    <ul>
      <li>mono type</li>
      <li>poly type</li>
    </ul>
</ul>
 *)
type t11 = int -> int;
val v11 : t11 = fn x => x + 11;

type 'a t12 = int -> 'a;
exception E12 of int;
val v12 : int t12 = fn x => raise E12 x;

type 'a t21 = 'a -> int;
val 'a v21 : 'a t21 = fn x => 21;

type ('a, 'b) t22 = 'a -> 'b;
exception E22;
val v22 : (int, int) t22 = fn x => x + 1;

