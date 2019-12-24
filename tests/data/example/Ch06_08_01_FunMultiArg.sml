fun powerUncurry (0,C) = 1
  | powerUncurry (n,C) = C * powerUncurry(n - 1, C);
powerUncurry (2, 3);
fun powerCurry 0 C= 1
  | powerCurry n C = C * (powerCurry (n - 1) C);
powerCurry 2 3;

