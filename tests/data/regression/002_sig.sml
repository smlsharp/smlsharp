structure A :
  sig
     datatype foo = A
     val f : foo -> foo
  end =
struct
  datatype foo = A
  val f = fn A => A
end;

(*
2011-08-11 ohori

This code causes BUG at type inference.

[BUG] EvalITy: non dty tfun in evalBuiltin
    raised at: ../types/main/EvalIty.sml:59.16-59.49
   handled at: ../typeinference2/main/typeinference.sml:1360.34
		../typeinference2/main/typeinference.sml:2949.28
		../toplevel2/main/Top.sml:705.65-705.68
		../toplevel2/main/Top.sml:759.37
		main/SimpleMain.sml:269.53

Fixed. Added case for REALIZED case in EvalTfun in EvalIty.sml
It then loop perhaps in MatchCompiler. 
A new case of 003 added for this MatchCompiler bug.

After the fix of bug 003 in MatchCompiler, this code still makes
the compiler loop, perhaps in FFICompilation.
The case may well be the same as that of 003.

This is a bug 003 and is fixed.

*)

