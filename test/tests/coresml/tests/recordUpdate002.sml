(*
record update expression with various right fields.

<ul>
  <li>the number of right fields
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
</ul>
*)
val v1 = {a = 1, b = 3} # {a = 11};

val v2 = {a = 2, b = true, c = "foo"} # {a = 22, b = false};
