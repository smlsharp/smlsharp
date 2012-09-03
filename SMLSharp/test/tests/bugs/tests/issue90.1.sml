structure Sval1 = struct val x = (1, 2) end;
structure Sval2 = struct open Sval1 val y = x end;
