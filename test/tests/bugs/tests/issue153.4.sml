functor F(P : sig val x : int end) = struct val x = P.x + 1 end;
structure P = struct val x = 1 end;
structure T = F(F(P));
