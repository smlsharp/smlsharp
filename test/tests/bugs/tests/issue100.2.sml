structure S1 = struct type t = int end;
structure S2 = struct open S1 val y = 1 : t end;
val x : S2.t = 2;
