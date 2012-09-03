(*
datatype constructor application in a datatype declaration with "withtype".

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
  <li>arity of type constructors in datatype
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
</ul>
*)
datatype 'a dt111 = D111 of int * 'a withtype t111 = bool * (int * int) dt111;
val x111 : t111 = (true, D111(1, (2, 3)));

datatype ('a,'b) dt112 = D112 of int * 'a * 'b
withtype t112 = bool * (string, bool) dt112
val x112 : t112 = (false, D112(1, "abc", true));
