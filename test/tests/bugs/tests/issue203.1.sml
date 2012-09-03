signature SIG = sig type t datatype dt = D of t end;

(* OK *)
structure STR1 : SIG = 
          struct type t = real datatype dt = D of real end;
(* NG *)
structure STR2 : SIG = 
          struct type t = int datatype dt = D of int end;
