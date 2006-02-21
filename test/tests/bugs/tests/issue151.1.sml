datatype 'a dtNeq = DNeq | ENeq of 'a;
fun f g x = case x of DNeq => () | ENeq v => (g v; ());
f (fn x => x * 1.0) (ENeq 1.23);

