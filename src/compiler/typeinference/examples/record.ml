fun f {a,...} = a;
fun g x = #a x;
val h = fn x => fn y => #a y x;
f {a =1, b = 2};
g {a = {b=1,c=true}, b = 2};
val i = h 3;
i {A = 1, a = fn x => x + 1};

