(*
parenthetic type.
rule 48

<ul>
  <li>inner type
  <ul>
    <li>type variable</li>
    <li>record type</li>
    <li>base type</li>
    <li>constructed type</li>
    <li>function type</li>
    <li>parenthetic type</li>
  </ul>
  </li>
</ul>
 *)

type 'a t1 = ('a);
val v1 : int t1 = 1;

type t2 = ({x : int});
val v2 : t2 = {x = 2};

type t3 = (int);
val v3 : t3 = 3;

type ('a, 'b) t41 = 'a * 'b * bool;
type t4 = ((int, string) t41);
val v4 : t4 = (4, "four", false);

type t5 = (int -> int);
val v5 : t5 = fn x => x + 5;

type ('a, 'b) t61 = 'a * 'b * bool;
type t6 = (((int, string) t61));
val v6 : t6 = (6, "six", true);
