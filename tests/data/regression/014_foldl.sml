infixr ::

fun it_list f =
  let fun it_rec a [] = a
        | it_rec a (b::L) = it_rec (f a b) L
  in it_rec
  end

(*
2011-08-13 katsu

This causes BUG at StaticAnalysis due to UncurryFundecl.

[BUG] function type is expected
    raised at: ../annotatedtypes/main/AnnotatedTypesUtils.sml:56.13-57.53
   handled at: ../staticanalysis/main/StaticAnalysis.sml:183.8
		../toplevel2/main/Top.sml:797.37
		main/SimpleMain.sml:269.53
2011-08-13 ohori
Fixed. This is due to an imcomplete refactoring of typeinfApplyId.
*)
