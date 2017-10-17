infixr ::
val empty = nil
fun get (foo::x) = (foo, x);
val (_, x) = get empty

(*
2011-11-28 ohori

This causes BUG at RecordCompilation.

TAG(FREEBTV(38))
[BUG] generateInstance
    raised at: ../recordcompilation/main/RecordCompilation.sml:309.26-309.56
   handled at: ../toplevel2/main/Top.sml:836.37
                main/SimpleMain.sml:368.53
*)

(*
2011-11-28 ohori

This is cased by the bug-fix of 141_provide.sml, where we enlarge the set of
non-expansive terms to contain 
  #l non-expansive-term
which are indeed non-expansive.

This chage exibits a hidden bug in decompose, which introduces 
compiler-generated local value bindings. The old decompose
does not increment the lambda depth for the expression inside of 
the newly introduced local value binding.
Due to this, free type variables appearing in an outer context 
get generalized.
*)
