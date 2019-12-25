val myCPoint = fn M => #CPoint M {x = 1.0, y = 1.0};
val myPPoint = fn M => #PPoint M {r = 1.41421356237, theta = 45.0};

val distance = 
{
  CPoint = fn {x, y, ...} => Real.Math.sqrt (x * x + y * y),
  PPoint = fn {r, theta, ...} => r
};

myCPoint distance;
myPPoint distance;
