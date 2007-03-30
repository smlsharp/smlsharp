(* single recursive datatypes. *)

(* arity of 2 type variables *)

datatype ('a, 'b) d12_1 = A12_1 of ('a, 'b) d12_1 | B12_1 of 'a;
A12_1(B12_1 1);
A12_1(B12_1 1.23);

datatype ('a, 'b) d12_2 = A12_2 of ('b, 'a) d12_2 | B12_2 of 'a;
A12_2(B12_2 1);
A12_2(B12_2 1.23);

(* mutual recursive datatypes. *)

(* arity of 1 type variable *)

datatype 'a d21_1 = A21_1 of 'a e21_1 | B21_1 of 'a
     and 'a e21_1 = C21_1 of 'a d21_1;
C21_1(A21_1(C21_1(B21_1 1)));

datatype 'a d21_2 = A21_2 of 'a e21_2 | B21_2 of 'a
     and 'a e21_2 = C21_2 of int d21_2;
C21_2(A21_2(C21_2(B21_2 1)));

(* arity of 2 type variables *)

datatype ('a, 'b) d22_1 = A22_1 of ('a, 'b) e22_1 | B22_1 of 'a
     and ('a, 'b) e22_1 = C22_1 of ('a, 'b) d22_1;
C22_1(A22_1(C22_1(B22_1 1)));

datatype ('a, 'b) d22_2 = A22_2 of ('a, 'b) e22_2 | B22_2 of 'a
     and ('a, 'b) e22_2 = C22_2 of ('b, 'a) d22_2;
C22_2(A22_2(C22_2(B22_2 1)));

datatype ('a, 'b) d22_3 = A22_3 of ('b, 'a) e22_3 | B22_3 of 'a
     and ('a, 'b) e22_3 = C22_3 of ('b, 'a) d22_3;
C22_3(A22_3(C22_3(B22_3 1)));

