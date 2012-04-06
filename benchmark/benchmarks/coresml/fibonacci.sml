fun fibonacci 0 = 1
  | fibonacci 1 = 1
  | fibonacci n = fibonacci (n - 1) + fibonacci (n - 2);

val x = fibonacci 40;

val _ = print (Int.toString x);
