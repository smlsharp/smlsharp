datatype foo = A of int | B of int;
case (2,B(5)) of 
    (1,A(1)) => 3
  | (_,B(x)) => x;
