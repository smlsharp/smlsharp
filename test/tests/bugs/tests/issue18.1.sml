val a1 = {a = 1};
val a2 = {a = {b = 2}};
#a a1;
#a a2;
fun f x = #a x;
f a1;
f a2;
