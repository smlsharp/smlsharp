fun id x = x;
id id;
fun K x y = x;
val a = fn (x,y) => K x (fn z => (z x,z y));
