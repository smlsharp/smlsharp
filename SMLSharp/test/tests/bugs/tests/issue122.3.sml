structure S = struct exception E end;
fun f S.E = print "OK" | f _ = print "WRONG";
f S.E;  (* A *)
signature S = sig exception E end;
structure S1 = S : S;
f S1.E;  (* B *)
