(*
same type variables occur in multiple abstype bindings in abstype declaration.
rule 17, 28

<ul>
  <li>the number of type variables
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
  <li>the number of abstype bindings
    <ul>
      <li>2</li>
    </ul>
  </li>
</ul>
 *)
abstype 'x1 t121 = C121 of 'x1 * int
and 'x1 t122 = C122 of int * 'x1
with
    val v12 : (bool t121 * real t122) = (C121(true, 121), C122(122, 1.22))
end;

abstype ('x1, 'x2) t221 = C221 of 'x1 * int * 'x2
and ('x1, 'x2) t222 = C222 of 'x2 * int * 'x1
with
    val v22 : ((bool, real) t221 * ((bool * real), (real * bool)) t222) =
        (C221 (true, 221, 22.1), C222 ((22.2, true), 222, (false, 2.22)))
end;

