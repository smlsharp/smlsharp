type ('a, 'b) t = ('b * 'a);
signature SIG = sig val f : ('a, 'b) t -> 'b end;
structure STR :> SIG = struct val f = fn (m, n) => m end;
STR.f;
STR.f ("a", 1);
