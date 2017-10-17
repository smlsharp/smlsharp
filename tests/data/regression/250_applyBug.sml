let val (f,x) = 1 in f 1 end;
(*
2013-3-1 ohori
This causes a bug exception

# let val (f,x) = 1 in f 1 end;
Compiler bug:InferType: var not found (1)

2013-3-1 ohori
fixed
*)
