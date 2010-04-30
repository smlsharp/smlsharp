fun id x = x;
val a = fn x => x;
val b = id a;
a 1;
b 1;
