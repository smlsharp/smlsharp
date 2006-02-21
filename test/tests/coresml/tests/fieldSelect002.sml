(*
polymorphic field selection expression.

<ul>
  <li>the number of fields in the kind of the type variable
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
  <li>the numer of nest of kind of the type variable
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
</ul>

 *)
fun f11 r = #x r;
val v111 = f11 {x = 1, y = 2};
val v112 = f11 {a = "foo", x = "bar"};

fun f12 r = #x(#a r);
val v121 = f12 {a = {x = 2, y = 3}, b = true};
val v122 = f12 {z = true, a = {x = "foo", y = "bar"}};

fun f21 r = (#x r, #y r);
val v211 = f21 {x = 1, y = 2};
val v212 = f21 {a = "foo", x = "bar", y = "boo"};

fun f22 r = (#x (#a r), #y (#a r), #v (#b r), #w (#b r));
val v221 = f22 {a = {x = 1, y = 2}, b = {v = 3, w = 4}};
val v222 = f22 {a = {x = "bar", y = "boo"}, b = {v = 1.23, w = 2.34}};
