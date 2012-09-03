(* OK *)
datatype dt21 = D21 of int * real;

(* NG *)
type t = int * real;
datatype dt21 = D21 of t;
