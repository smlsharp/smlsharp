(*
multiple occurrences of multiple type variables in abstype declaration.
rule 17, 28

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
  <li>the number of data constructors
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
</ul>
 *)

abstype 'x1 t11 = C11 of 'x1 * int
with val v11 : bool t11 = C11 (false, 1) end;

abstype 'x1 t121 = C121 of 'x1 * ('x1 * int)
with val v121 : bool t121 = C121 (true, (false, 1)) end;

abstype 'x1 t122 = C1221 of 'x1 | C1222 of 'x1 * int
with val v122 : bool t122 * string t122 = (C1221 true, C1222 ("foo", 1)) end;

abstype ('x1, 'x2) t211 = C211 of 'x1 * ('x2 * int)
with val v211 : (bool, real) t211 = C211 (true, (2.11, 211)) end;

abstype
  ('x1, 'x2) t212 = C2121 of 'x1 * int | C2122 of 'x2 * bool
with
  val v212 : (bool, real) t212 * (int, string) t212 =
      (C2121 (true, 2121), C2122 ("foo", false))
end;

abstype
('x1, 'x2) t221 = C221 of 'x1 * ('x2 * int) * 'x2 * ('x1 * int)
with
val v221 : (bool, real) t221 =
    C221 (true, (2.211, 2211), 2.212, (false, 2212))
end;

abstype
('x1, 'x2) t222 =
C2221 of 'x1 * ('x2 * int) | C2222 of 'x2 * ('x1 * int)
with
val v222 : (bool, real) t222 * (bool * real, real * bool) t222 =
    (
      C2221 (true, (2.211, 2221)),
      C2222 ((2.212, true), ((false, 2.213), 2222))
    )
end;

