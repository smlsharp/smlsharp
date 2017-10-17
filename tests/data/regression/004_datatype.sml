datatype foo = A
val f = fn (A x) => A x

(*
2011-08-11 ohori

This code causes typeinference.
VAL REC optimize:
 ...
val f(v0) = fn A(c18) x(v1) => A(c18) x(v1)
uncaught exception: CoerceFun: CoerceFun
    raised at: ../types/main/TypesUtils.sml:573.22-573.31
   handled at: ../typeinference2/main/typeinference.sml:2949.28
		../toplevel2/main/Top.sml:705.65-705.68
		../toplevel2/main/Top.sml:759.37
		main/SimpleMain.sml:269.53

Fixed. 2011-08-11.

*)

