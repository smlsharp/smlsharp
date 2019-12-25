
datatype d1 = D1
datatype ('a, 'b) d2 = D21 of 'a
                     | D22 of 'b

datatype d31 = D31 of d32
     and d32 = D321 of d31
             | D322

datatype d4 = D4 of t1
withtype t1 = int

infix D5
datatype d5 = D5 of int * int

val d1 = D1
