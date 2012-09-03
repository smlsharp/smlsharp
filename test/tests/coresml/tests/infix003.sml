(*
infix data constructor.

<ul>
  <li>infix application
    <ul>
      <li>yes</li>
      <li>no</li>
    </ul>
  </li>
  <li>infix constructor pattern
    <ul>
      <li>yes</li>
      <li>no</li>
    </ul>
  </li>
</ul>
 *)
infix 1 $$;

datatype t = $$ of int * int;
val v11 = case 1 $$ 2 of x $$ y => x + y;
val v22 = case op $$ (2, 3) of op $$ (x, y) => x + y;