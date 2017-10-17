datatype foo = A
val f = fn A => A

(*
2011-08-11 ohori

This code causes MatchCompiler loops.

2011-08-11 ohori
Fixed in MatchCompiler.
 patListTpexpUseCountList computation cause loops in TPCASEM.
 due to the change of rule type from (patList, exp) to
 {args:patList, body:exp}.

The results still causes loop perhaps in doFFICompilation.

2011-08-11 ohori
FIXED. This is a simple bug in RC.RCCASE in FFICompilation.

The results still causes a bug perhaps in X86Select:
Datatype Compiled:
  ...
val f(0) = fn $T_a(1) => ( cast 0 to {}foo(t28) )
[BUG] makePad
    raised at: ../rtl/main/X86Select.sml:2899.18-2899.39
   handled at: ../toplevel2/main/Top.sml:759.37
		main/SimpleMain.sml:269.53
[atsushi@myVineLinux tests]$ 
*)

(*
2011-08-13 katsu

Fixed.

The above bug was caused due to a bug of DatatypeCompilation.

*)
