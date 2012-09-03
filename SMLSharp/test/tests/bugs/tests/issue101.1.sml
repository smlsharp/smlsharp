structure S1 = let structure S11 = struct val x = 1 end in S11 end;
S1.x;
local structure S21 = struct val x = 1 end in structure S2 = S21 end;
S2.x;
