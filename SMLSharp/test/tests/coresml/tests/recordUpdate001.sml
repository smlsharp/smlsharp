(*
record update expression with various left expression.

<ul>
  <li>left expression
    <ul>
      <li>record expression</li>
      <li>variable expression of record type</li>
      <li>variable expression of record kind</li>
      <li>nested record update expression of record type</li>
      <li>nested record update expression of record kind</li>
    </ul>
  </li>
</ul>
*)
val v1 = {a = 1, b = "foo"} # {a = 11, b = "bar"};

val v2 = let val lv2 = {a = 2, b = "bar"} in lv2 # {a = 22, b = "baz"} end;

fun f3 r = r # {a = 33, b = 3.33};
val v3 = f3 {a = 3, b = 0.3, c = 4};

val v4 =
    {a = 4, b = "four", c = 45.6}
        # {a = 44, b = "fourteen"}
        # {b = "forty", c = 56.7};

fun f5 r = r # {a = 55, b = 5.55} # {b = 555.0, c = "five-five"};
val v5 =
    (
      f5 {a = 1, b = 1.23, c = "fff"},
      f5 {a = 2, b = 2.34, c = "ggg", d = true}
    );
