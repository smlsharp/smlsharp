fun f real 0 s = ""
  | f real n s = f 0.0 (n - 1) s;
f 0.0 1 [];