(* load.sml
 *
 * COPYRIGHT (c) 1993, AT&T Bell Laboratories.
 *
 * Code to build the tree from a list of bodies.
 *)

signature LOAD =
  sig

    structure S : SPACE
    structure V : VECTOR

    val makeTree : (S.body list * real V.vec * real) -> S.space

  end; (* LOAD *)
