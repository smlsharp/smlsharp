datatype ''a dt = D of ''a;
fun f_dt f_a x = case x of D y => f_a y;
val x = f_dt (fn {b} => b) (D {b = "abc"});


datatype 'a p = P of 'a;
fun f_p f_a x = case x of P x => f_a x;
val x = f_p (fn () => "()") (P ());


datatype 'a p = P of 'a;
fun f_p f_a x = case x of P x => f_a x;
val x = f_p (fn {x} => "x") (P {x = 111});
