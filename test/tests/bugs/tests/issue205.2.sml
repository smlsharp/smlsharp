
(* OK *)
(* simplex backward dependency *)

datatype t21 = C21 of int and t22 = C22 of t21;

(* NG *) 
(* simplex forward dependency *)

datatype t21 = C21 of t22 and t22 = C22 of int;

(* NG *)
(* mutual simple dependency *)
(* Caution: type inferencer sticks. *)
datatype t21 = C21 of t22 and t22 = C22 of t21;

(* NG *) 
(* mutual dependency *)
(* temporarily commented out *)
datatype t21 = C21 of t22 and t22 = C22 of t21 * bool;
