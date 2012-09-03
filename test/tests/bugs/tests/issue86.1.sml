fun f x = x + 1;
f 1;
val f' : int -> int = f;
f' 1;
type func = int -> int;
val f'' : func = f;
f'' 1;
