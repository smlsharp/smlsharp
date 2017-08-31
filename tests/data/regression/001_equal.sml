infix 4 =
val x = () = ()

(*
2011-08-09 katsu

this code causes BUG.

at type inference:

[BUG] tpappTy:{}unit(t7) * {}unit(t7) -> {}bool(t13), {{}unit(t7) * {}unit(t7) -> {}bool(t13)|
    raised at: ../types/main/TypesUtils.sml:842.9-847.18
   handled at: ../toplevel2/main/Top.sml:759.37
		main/SimpleMain.sml:269.53

2011-08-09 ohori

The above is a bug in typeinference.sml and is fixed.
There remains a bug perhaps in staticanalysis (see below.)

Datatype Compiled:
  ...
val x(0) =
  let val $1(1) = (((), ()))
  in
    Equal
    {{}unit(t7)}
    ($1(1)[_indexof(1, {}unit(t7) * {}unit(t7))],
    $1(1)[_indexof(2, {}unit(t7) * {}unit(t7))])
  end
[BUG] function type is expected
    raised at: ../staticanalysis/main/StaticAnalysis.sml:270.28-270.67
   handled at: ../toplevel2/main/Top.sml:759.37
		main/SimpleMain.sml:269.53
*)

(*
2011-08-12 katsu

fixed by changeset b650ea73a0fe.
*)
