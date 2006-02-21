(*
type construction.
rule 46

<ul>
  <li>applied type expression
    <ul>
      <li>type variable</li>
      <li>record type</li>
      <li>base type</li>
      <li>applied type constructor</li>
      <li>mono function type</li>
      <li>poly function type</li>
      <li>parenthetic type</li>
    </ul>
  </li>
</ul>
 *)
type 'a t = 'a * bool;

type 'a t1 = ('a * bool) t;
val v1 : int t1 = ((1, true), false);

type t2 = {x : int} t;
val v2 : t2 = ({x = 2}, false);

type t3 = int t;
val v3 : t3 = (3, true);

type t4 = (int t) t;
val v4 : t4 = ((4, true), false);

type t5 = (int -> int) t;
val v5 : t5 = (fn x => x + 1, true);

type 'a t6 = ('a -> 'a) t;
val v6 : int t6 = (fn x => x + 1, true);

type t7 = (int) t;
val v7 : t7 = (7, false);
