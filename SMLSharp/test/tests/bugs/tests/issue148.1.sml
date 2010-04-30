datatype 'x1 t122 = C of 'x1 | D of 'x1 * int;
fun f g (C x) = "C"
  | f g (D x) = case x of (a, b) => (g a);
fun h (x : string) = x;
f h (D ("foo", 1));

