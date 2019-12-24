fun f {X = x, Y = y} = (x, y);

fun f {X = x, Y = y, ...} = (x, y);

fun f {X, Y, ...} = (X,Y);

fun f ({X,...}::_) = X;

