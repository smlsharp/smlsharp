fun P x y = (x,y);
fun f x = #name x;
fun g x = #age x;
val PairFG = P f g;
fun test x = (#1 PairFG x, #2 PairFG x);
test {name="joe", office="I51b", age=21};
