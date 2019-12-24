fun moveX (p as {X:real,Vx:real,...}, t:real) = p # {X = X + Vx};
fun moveY (p as {Y:real,Vy:real,...}, t:real) = p # {Y = Y + Vy};
fun accelerateX (p as {Vx:real,...}, t:real) = p;
fun accelerateY (p as {Vy:real,...}, t:real) = p # {Vy = Vy + 9.8};

fun tic (p, t) =
let
  val p = accelerateX (p, t)
  val p = accelerateY (p, t)
  val p = moveX (p, t)
  val p = moveY (p, t)
in
  p
end;

fun accelerateX (p as {Vx:real,...}, t:real) = p # {Vx = Vx * 0.90};
