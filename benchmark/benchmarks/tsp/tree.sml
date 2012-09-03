(* tree.sml
 *
 * COPYRIGHT (c) 1994 AT&T Bell Laboratories.
 *
 * Trees for the TSP program.
 *)

structure Tree =
  struct

    datatype tree
      = NULL
      | ND of {
	    left : tree, right : tree,
	    x : real, y : real,
	    sz : int,
	    prev : tree ref, next : tree ref
	  }

    fun mkNode (l, r, x, y, sz) = ND{
	    left = l, right = r, x = x, y = y, sz = sz,
	    prev = ref NULL, next = ref NULL
	  }

    fun printTree (outS, NULL) = ()
      | printTree (outS, ND{x, y, left, right, ...}) = (
	  TextIO.output(outS, String.concat [
	    Real.toString x, " ", Real.toString y, "\n"]);
	  printTree (outS, left);
	  printTree (outS, right))

    fun printList (outS, NULL) = ()
      | printList (outS, start as ND{next, ...}) = let
	  fun cycle (ND{next=next', ...}) = (next = next')
	    | cycle _ = false
	  fun prt (NULL) = ()
	    | prt (t as ND{x, y, next, ...}) = (
		TextIO.output(outS, String.concat [
		    Real.toString x, " ", Real.toString y, "\n"
		  ]);
		if (cycle (!next))
		  then ()
		  else prt (!next))
	  in
	    prt start
	  end

  end;

