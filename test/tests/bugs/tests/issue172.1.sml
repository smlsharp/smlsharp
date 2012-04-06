signature SIG1 = sig datatype dt = D end;
structure STR1 = struct datatype dt = D end;

signature SIG2 = sig type dt type st = dt end;
structure STR2 = struct type dt = STR1.dt type st = dt end;

signature SIG3 =
sig
  structure STR1 : SIG1
  structure STR2 : SIG2
  sharing type STR1.dt = STR2.dt
end;
structure STR3 :> SIG3 =
struct
  structure STR1 = STR1
  structure STR2 = STR2
end;
