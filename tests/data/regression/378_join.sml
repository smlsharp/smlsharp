infixr ::
fun f nil = raise Fail "nil"
  | f [x] = x
  | f (x :: y :: l) = f (_join(x, y) :: l);

(*
This must typecheck as follows:
  val f = fn : ['a#reify. ('a = 'a join 'a) => 'a list -> 'a]
but this causes Bug at PolyTyElimination.
  Bug.Bug: PolyTyElimination: equal at src/compiler/compilePhases/polytyelimination/main/PolyTyElimination.sml:17.14(302)
*)
