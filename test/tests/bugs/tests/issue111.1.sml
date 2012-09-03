fun id x = x;
datatype 'a dt = D of 'a;
val y = D id;
val D z = y;
