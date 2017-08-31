datatype foo = A of int
val f = fn A x => A x 

(*
2011-08-11 ohori

This code causes MatchCompiler bug.
val f(0) =
    (fn $T_a(2) =>
        (case (match) $T_a(2) :{ {}foo(t28) }
           of A(18) x(1) :{}foo(t28) => A(18) x(1) : {}foo(t28))
          :{}foo(t28))
[BUG] MatchCompiler: Non conty in userdefined type
    raised at: ../matchcompilation/main/MatchCompiler.sml:382.26-382.61
   handled at: ../matchcompilation/main/MatchCompiler.sml:1496.27-1496.30
		../toplevel2/main/Top.sml:759.37
		main/SimpleMain.sml:269.53

2011-08-11 ohori.
Fixed. 
This is a bug in 
  fun getTagNums {ty, path, id} = 
where ty is either FUNMty or CONSTRUCTty.
The former case is missing.

The results still make the compiler loop, perhaps in FFICompilation.

2011-08-11 ohori
FIXED.  The case of RCRAISE recursively calls on the same given exp.

The results still causes bug, perhaps in RecordUnboxing.

Datatype Compiled:
 ...
val f(0) =
  fn $T_a(2) =>
    let
      val x(4) =
        ( cast $T_a(2) to {1: {}int(t0)} )[_indexof(1, {1: {}int(t0)})]
    in ( cast ({1 = x(4)}) to {}foo(t28) ) end
[BUG] transformExp: ACINDEXOF
    raised at: ../recordunboxing/main/RecordUnboxing.sml:407.24-407.61
   handled at: ../toplevel2/main/Top.sml:759.37
		main/SimpleMain.sml:269.53

*)

(*
2011-08-11 katsu

fixed by changeset d6a5e24e80ee and f563e7de020f.

This was due to the bug of how to deal with explicit record index
in StaticAnalysis and RecordUnboxing.

*)
