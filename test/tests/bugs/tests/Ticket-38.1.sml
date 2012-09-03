signature SIG = sig structure S : sig type t val x : t end end;
structure STR :> SIG =
struct structure S = struct datatype t = D val x = D end end;
structure T = STR.S;
