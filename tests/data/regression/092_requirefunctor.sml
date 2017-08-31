_interface "092_requirefunctor.smi"
structure S = F (
  fun f x = x : int
);

(*
2011-08-30 katsu

This causes BUG at InferType.

[BUG] InferType: var not found
    raised at: ../typeinference2/main/InferTypes.sml:2079.35-2079.54
   handled at: ../typeinference2/main/InferTypes.sml:2319.49
                ../typeinference2/main/InferTypes.sml:3656.28
                ../toplevel2/main/Top.sml:766.65-766.68
                ../toplevel2/main/Top.sml:868.37
                main/SimpleMain.sml:359.53
*)

(*
2011-09-01 ohori

Fixed the above bug by allowing that a functor variable be
external.

This is rather special in that 
(1) F has a polytype with the empty set of bound type variable
(2) the first argument is a function of type {} -> {}
Both of them can be eliminated if desired.

This now produce the following static analysis bug:

datatypecompilation done
[.
  (({}^{G,B,A} -f5-> {}^{G,B,A})^{G,B}
   -f8-> ((int(t0[]) -f6-> int(t0[]))^{G,B} -f7-> unit(t7[]))^{G,B})
  ^{G,B}]expandFunTy fails
tlexp:
EXVAR(F) (fn id(5) : {} => id(5))
funTy:
({} -> {}) -> (int(t0[]) -> int(t0[])) -> unit(t7[])
funExp:
EXVAR(F)
newfunExp:
EXVAR(F)
newFunTy:
[.
  (({}^{G,B,A} -f5-> {}^{G,B,A})^{G,B}
   -f8-> ((int(t0[]) -f6-> int(t0[]))^{G,B} -f7-> unit(t7[]))^{G,B})
  ^{G,B}]

[BUG] function type is expected
    raised at: ../annotatedtypes/main/AnnotatedTypesUtils.sml:56.13-57.53
   handled at: ../staticanalysis/main/StaticAnalysis.sml:201.28
		../toplevel2/main/Top.sml:868.37
		main/SimpleMain.sml:359.53

*)

(*
2011-09-02 ohori

Refined the functor abstraction so that
1. if there is no lifted tvars, then it does not produce the first arg.
2. if there is no functor args then it does not produce the second list of
   args.
3. if there is no bound type variables then it does not produce the empty 
   polytype abstraction.
4. if there is neither the first arg nor the second arg, then it produce
   a function on unit type.

With these refinment, the above bug in staticanalysis disappears.

*)

