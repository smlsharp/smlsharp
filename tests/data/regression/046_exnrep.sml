_interface "046_exnrep.smi"
structure S =
struct
  exception E
end
exception E = S.E

(*
2011-08-22 katsu

This causes BUG at StaticAllocation.

[BUG] unionTopEnv:
SMLN1S1EE:  GLOBALVAR(SA_C0.001<G>:BOXED : BOXED : 0x4)
SMLN1S1EE:  GLOBALVAR(SA_C0.001<G>:BOXED : BOXED : 0x4)
    raised at: ../yaanormalization/main/StaticAllocation.sml:37.19-40.76
   handled at: ../toplevel2/main/Top.sml:861.37
                main/SimpleMain.sml:359.53
*)

(*
2011-08-22 katsu

This is due to a bug of NameEval that generates two EXPORTEXNs of same exnId.

Name Evaluation:
...
exception S.E(e0)
export exception S.E.E(e0)
export exception E.E(e0)

Datatype compilation translates these two EXPORTEXNs to two identical
EXPORTVARs since they have same exnId.

val S.E(0) : SMLSharp.boxed(t12) =
    cast(_PRIMAPPLY(Array_array) string(t4) (1, "S.E"))
export val S.E(0)
export val S.E(0)

Due to this duplication, backend produces doubled external symbols in
one object code.

*)


(*
2011-08-23 ohori

This contains two problems. 
1. One is a bug in external exception name generation.
  The above exception names should be S.E and E instead of S.E.E and E.E. 
  This is fixed.

2. duplicate export. 
If one write an interface,

  structure S =
  struct
    exception E
  end
  exception E

one interpretation is to assert that two generative exceptions are created.
If one want to specify that two exceptions be the same, then one would write:

  structure S =
  struct
    exception E
  end
  exception E = exception S.E

This is one and simple solution.

Added the code to process this, and this now results in

046_exnrep.smi:5.11-5.11 Error:
  (name evaluation 142) Provide check fails (generative exception definition
  expected) : E

as expected.
*)


(*
2011-09-08 ohori

This causes a BUG exception again.

staticallocation done
[BUG] mergeProgram
    raised at: ../aigenerator2/main/AIGenerator.sml:3433.28-3433.54
   handled at: ../aigenerator2/main/AIGenerator.sml:3601.27-3601.30
		../toplevel2/main/Top.sml:868.37
		main/SimpleMain.sml:368.53

by name evaluator exporting two exception id.

Since the following code should be allowd:
  In provide:
    exception E
  
  In source
    let
      exception F
    in
      exception E = F
    end
exception E = F should be allowed to macth exception E in provide.

The solution is to reject exporting the same exception id twice.

FIXED.
*)
