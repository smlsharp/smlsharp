infixr 5 :: @

fun op @ (nil, l) = l
  | op @ (a::r, l) = a :: (r@l)

(*
2011-08-12 ohori

This causes bug probably in Datatypecompilation.
[BUG] tpappTy:int(t0) * int(t0) list(t14) -> int(t0) list(t14), {int(t0)}
    raised at: ../types/main/TypesUtils.sml:848.9-855.20
   handled at: ../recordcompilation/main/RecordCompilation.sml:480.42
		../toplevel2/main/Top.sml:778.37
		main/SimpleMain.sml:269.53

See 010_cons.sml for a simpler example.

After the 010 bug fixed, this code causes bug in StaticAnalysis:
[BUG] StaticAnalysis:unification fail(6)
    raised at: ../staticanalysis/main/StaticAnalysis.sml:449.35-449.60
   handled at: ../toplevel2/main/Top.sml:792.37
		main/SimpleMain.sml:269.53

See 012_case.sml for a simpler bug.

*)

(*
2011-08-13 katsu

This causes BUG in StaticAnalysis.

Unification fails (2) t22,t21
unification fail(6)
tlexp
case cast(_PRIMAPPLY(IdentityEqual) (cast($T_e(9)), NULLBOXED)) of
  0 =>
  ...(CASE1)...
| _ =>
  ...(CASE2)...
exp
  ...(CASE1)...
defaultExp
  ...(CASE2)...

[BUG] StaticAnalysis:unification fail(6)
    raised at: ../staticanalysis/main/StaticAnalysis.sml:460.28-460.53
   handled at: ../toplevel2/main/Top.sml:797.37
		main/SimpleMain.sml:269.53

2011-08-13 katsu

The above bug is fixed by changeset 7a4278249f90.

But another BUG is caused at BitmapCompilation.

[BUG] MVRECORD: not found
    raised at: ../bitmapcompilation/main/BitmapCompilation.sml:358.37-358.70
   handled at: ../toplevel2/main/Top.sml:797.37
		main/SimpleMain.sml:269.53

2011-08-13 katsu

Fixed by changeset fa0265123ca9.

*)
