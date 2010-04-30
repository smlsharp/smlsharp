functor FVal(S : sig val x : int end) = struct val y = S.x end;
structure TVal = FVal(struct val x = 2 end);

