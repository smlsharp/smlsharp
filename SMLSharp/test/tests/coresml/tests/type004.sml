(*
same type variables occur in multiple type bindings in type declaration.
rule 16, 27

<ul>
  <li>the number of type variables
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
  <li>the number of type bindings
    <ul>
      <li>2</li>
    </ul>
  </li>
</ul>
 *)
type 'x1 t121 = 'x1 * int and 'x1 t122 = int * 'x1;
val v12 : (bool t121 * real t122) = ((true, 121), (122, 1.22));

type ('x1, 'x2) t221 = ('x1 * int * 'x2)
and ('x1, 'x2) t222 = ('x2 * int * 'x1);
val v22 : ((bool, real) t221 * ((bool * real), (real * bool)) t222) =
    ((true, 221, 22.1), ((22.2, true), 222, (false, 2.22)));

