fun powerCurry 0 C= 1
  | powerCurry n C = C * (powerCurry (n - 1) C);

val square = powerCurry 2;

fun Sigma f 0 = 0
  | Sigma f n = f n + Sigma f (n - 1);

Sigma square 3;
Sigma (powerCurry 3) 3;
