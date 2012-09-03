(*
type constructor application in a datatype declaration with "withtype".

<ul>
  <li>the number of type constructors in datatype
    <ul>
      <li>1</li>
    </ul>
  </li>
  <li>the number of type constructors in withtype
    <ul>
      <li>1</li>
    </ul>
  </li>
  <li>arity of type constructors in withtype
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
</ul>
*)
datatype dt111 = D111 of (int * int) t111 * int withtype 'a t111 = 'a * bool;
val x111 = D111(((1, 2), true), 3);

datatype dt112 = D112 of (int * int, string * string) t112 * int
withtype ('a, 'b) t112 = 'a * bool * 'b;
val x112 = D112(((1, 2), true, ("abc", "xyz")), 3);
