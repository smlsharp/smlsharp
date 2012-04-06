signature SIG = sig datatype t = D end;
structure STR :> SIG = struct datatype t = D end;
datatype t = datatype STR.t;

fun f D = true;
val x = f STR.D;
