datatype 'a d = A of 'a | B of int d;
val x = B (A 1); (* safe case *)
val x : real d = B (A 1); (* error case *)


