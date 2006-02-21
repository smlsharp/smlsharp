val x = [#a, #b];
val v1 = case x of [x, y] => [x, y] | _ => x;
val v2 = case x of [] => 0 | (_ :: _) => 1;
