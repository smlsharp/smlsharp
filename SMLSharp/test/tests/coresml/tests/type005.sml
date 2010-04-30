(*
type declaration which also uses alias type declared by other declaration.
rule 16, 27

<ul>
  <li>the number of type declarations related.
    <ul>
      <li>2</li>
      <li>3</li>
    </ul>
  </li>
</ul>
 *)
type t21 = string * int;
type t22 = {a : t21, b : t21 * real};
val v2 : t22 = {a = ("a", 1), b = (("b", 2), 2.345)};

type t31 = {a : int, b : int -> int};
type t32 = t31 list;
type t33 = t32 * string;
val v3 : t33 = ([{a = 1, b = fn x => x + x}, {a = 2, b = fn x => x - x}], "x");
