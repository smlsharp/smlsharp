(*
type declaration.
rule 16, 27

<ul>
  <li>the number of type variables
    <ul>
      <li>0</li>
      <li>1</li>
      <li>2</li>
      <li>2, but one of them is not used in body</li>
    </ul>
  </li>
</ul>
 *)
type t1 = int;
val v1 : t1 = 1;

type 'x t2 = 'x * int;
val v2 : bool t2 = (true, 2);

type ('x, 'y) t3 = {a : 'x, b : 'y};
val v3 : (int, bool) t3 = {a = 3, b = false};

type ('x, 'y) t4 = {a : 'x};
val v4 : (int, bool) t4 = {a = 3};
