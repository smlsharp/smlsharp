fun id x = x;
val f2 = fn (x : 'a) => fn y => (x, y);
val fRecord22 = fn x => f2 {a = id, b = x};
val ({a, b}, c) = fRecord22 1 "a";
