(*
replication of long ID exception constructor
*)
structure S1 = struct exception E end;
exception E = S1.E;
fun f1 x = case x of S1.E => 1 | _ => 2;
val x = f1 E;
