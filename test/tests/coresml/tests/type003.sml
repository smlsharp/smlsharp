(*
multiple occurrences of multiple type variables in type declaration.
rule 16, 27

<ul>
  <li>the number of type variables
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
  <li>the number of occurrence of a type variable
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
</ul>
 *)
type 'x t11 = 'x * int;
val v11 : string t11 = ("foo", 2);

type 'x t12 = 'x * int * 'x;
val v12 : bool t12 = (true, 12, false);

type ('y, 'x) t21 = 'y * int * 'x;
val v21 : (bool, string) t21 = (false, 21, "bar");

type ('y, 'x) t22 = 'y * int * 'y * 'x * real * 'x;
val v22 : (bool, string) t22 = (true, 22, false, "baz", 1.23, "boo");
