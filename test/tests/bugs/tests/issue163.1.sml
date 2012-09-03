fun f x = {a = x, b = x};
fun g {a, b} = 1;

(* OK *)
fun h1 x = let val v = f x in g v end;

(* OK *)
fun h2 x = let val v as {a, b, ...} = f x in g v end;

(* OK *)
fun h3 x = let val v as {a, ...} = {a = x, b = x} in g v end;

(* NG *)
fun h4 x = let val v as {a, ...} = f x in g v end;
