fun powerCurry 0 C= 1
  | powerCurry n C = C * (powerCurry (n - 1) C);

val square = powerCurry 2;
square 3;
fun apply f = f 3;
apply square;
