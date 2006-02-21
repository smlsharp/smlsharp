(*
type constructor application in a abstype declaration with "withtype".

<ul>
  <li>the number of type constructors in abstype
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
abstype dt111 = D111 of (int * int) t111 * int withtype 'a t111 = 'a * bool
with
val x111 = D111(((1, 2), true), 3)
end;

abstype dt112 = D112 of (int * int, string * string) t112 * int
withtype ('a, 'b) t112 = 'a * bool * 'b
with
val x112 = D112(((1, 2), true, ("abc", "xyz")), 3)
end;
