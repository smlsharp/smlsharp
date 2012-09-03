structure Vector =
struct
  type 'a vector = int * int
  fun 'a fromList (list : 'a list) = (1, 2);
end;
structure Array =
struct
  type 'a array = 'a Vector.vector
  type 'a vector = 'a Vector.vector
  open Vector
end;

signature VECTOR =
sig
  type 'a vector
  val fromList : 'a list -> 'a vector
end;
signature ARRAY =
sig
  type  'a array
  eqtype 'a vector
  val fromList : 'a list -> 'a array
end;

structure S :>
sig
  structure V : VECTOR
  structure A : ARRAY
  sharing type V.vector = A.vector
end =
struct
  structure V = Vector
  structure A = Array
end;

structure Vector = S.V;
structure Array = S.A;

val vl = Vector.fromList [1];
val al = Array.fromList [1];
