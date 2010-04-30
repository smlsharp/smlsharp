signature SIG = sig type t end;
structure STR = struct datatype t = E end;
structure STrans = STR : SIG;
val xSTrans = STrans.E;
