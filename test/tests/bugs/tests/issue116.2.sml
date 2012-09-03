signature S = sig val f : int -> int end;
structure S = struct val f = fn x => x end;
structure T = S : S;
T.f;
