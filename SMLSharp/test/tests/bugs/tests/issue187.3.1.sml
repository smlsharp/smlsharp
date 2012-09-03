type ('a, 'b) t = {m : 'b, n : 'a};
signature SIG = sig val f : {y : ('a, 'b) t, z : 'b} -> 'b end;
structure STR :> SIG = 
struct val f = fn {y as {m : 'a, n : 'b}, z : 'a} => z end;
STR.f;
STR.f {y = {m = "a", n = 1}, z = "b"};
