(*
record type expression.
rule 45, 49

<ul>
  <li>type of the field.
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
type 'a t1 = {x : 'a};
val v1 : int t1 = {x = 1};

type t2 = {x : {y : int}};
val v2 : t2 = {x = {y = 2}};

type t3 = {x : int};
val v3 : t3 = {x = 3};

type 'a t41 = ('a * int);
type t4 = {x : bool t41};
val v4 : t4 = {x = (true, 4)};

type t5 = {x : int -> int};
val v5 = {x = fn x => x + 1};

type 'a t6 = {x : 'a -> ('a * int)};
val v6 = {x = fn x => (x, 6)};

type t7 = {x : (int * bool)};
val v7 = {x = (7, false)};
