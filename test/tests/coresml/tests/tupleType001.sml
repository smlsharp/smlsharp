(*
proper handling of precedence between tuple type constructor and other
type expressions.

<ul>
  <li>type expression containing a tuple type expression
    <ul>
      <li>top level</li>
      <li>constructed type</li>
      <li>function type</li>
    </ul>
  </li>
</ul>
 *)
type t1 = int * int;
val v1 = (1, 2);

(* type construction > tuple type *)
type 'a t21 = 'a * int;
type t2 = int * int t21;
val v2 : t2 = (1, (2, 3));

(* tuple type > function type *)
type t3 = int * int -> int * int;
val v3 : t3 = fn (x, y) => (x + y, x - y);
