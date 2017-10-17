exception Failure
val x = (Failure, 999);
val y = #1 x;

(*
2011-08-16 ohori

This cases a BUG exception in StaticanAlysis, probably due to 
imcomplete datatypecompilation. 

datatypecompilation done
Unification fails (3)
exn(t10)              <=== original exn type
{1: boxed(t12)}^{L1}  <=== result of exn type

[BUG] StaticAnalysis:TLSELECT: unification fail
    raised at: ../staticanalysis/main/StaticAnalysis.sml:314.29-314.61
   handled at: ../toplevel2/main/Top.sml:828.37
		main/SimpleMain.sml:269.53

It seems that exn record should be casted to exn type. The other possibility
of compiling exn type may not work since exn terms have two different record
structures depending whether they have arguments or not. 

*)

(*
2011-08-16 katsu

Fixed by changeset ea44bbeb3115.
The cast to "exn" type was missing.

*)
