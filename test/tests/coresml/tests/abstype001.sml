(*
abstype declaration.
rule 17, 28

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
abstype t1 = C1 of int
with val v1 = C1 1 end;

abstype 'x t2 = C2 of 'x * int
with val v2 : bool t2 = C2 (true, 2) end;

abstype ('x, 'y) t3 = C3 of {a : 'x, b : 'y}
with val v3 : (int, bool) t3 = C3 {a = 3, b = false} end;

abstype ('x, 'y) t4 = C4 of {a : 'x}
with val v4 : (int, bool) t4 = C4 {a = 3} end;
