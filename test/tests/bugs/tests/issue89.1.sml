structure S = struct fun f x = x + 1 end;
structure T = S;
structure S = struct fun f (x, y) = x + y end;
T.f 1;
