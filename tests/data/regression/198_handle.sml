exception E;
(*
fun f() = (print "E0\n";raise ((print "E1\n"; raise E) handle E => (print "E2\n";raise (print "E3\n";E)))) handle E => 1;
*)
(*
val vRaise = (raise ((raise E) handle E => raise E)) handle E => 1;
*)
val vRaise = ((raise E) handle E => raise E) handle E => 1

(*
2012-05-18 katsu

This seems to cause infinite loop.

2012-7-11 ohori 
slightly simplified to print the sources.
f() causes infinite loop.
*)

(*
2012-08-07 katsu

Fixed by changeset 251b54794b67.
*)
