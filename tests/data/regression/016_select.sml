val x = #1 (nil,1)

(*
2011-8-13 ohori.
This code causes BUG exception in static analysis.

The situation is probably due to the failure of compiling a POLYty
inside of RCINDEXOF term in RecordCompilation. Note that a rank-1 
type inference generates a RECORDty containing POLYty, as shown 
by this code.

A temporaly fix is made in RecordCompilation.

*)

(*
2011-08-14 katsu

fixed by changeset ce372979d9af.
This bug was due to missing compilation of type annotation of RCINDEXOF
at RecordCompilation.

*)
