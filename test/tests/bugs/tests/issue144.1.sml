signature SIG = sig type t val x : t end;
structure STR = struct type t = string val x = "a" end;
structure SS = STR : SIG;
structure SSTrans = STR : SIG;
val x = SSTrans.x;

