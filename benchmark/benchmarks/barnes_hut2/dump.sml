(* dump.sml
 *
 * COPYRIGHT (c) 1993, AT&T Bell Laboratories.
 *
 * Code to dump out the tree as a ``dot'' specification.
 *)

structure Dump =
  struct
    structure M = Main
    structure S = Space
    structure V = Vector

    fun dumpTree (fname, root, bodies) = let
	  val strm = IO.open_out fname
	  fun print (fmt, items) = IO.output (strm, Format.format fmt items)
	  fun indent i = Format.LEFT(i+i, Format.STR "")
	  fun bodyName b = let
		fun find ([], _) = raise Fail "bodyNd"
		  | find (b'::r, i) = if (b = b') then i else find(r, i+1)
		in
		  find (bodies, 0)
		end
	  fun bodyNd (i, id, b) =
		print ("%s  nd%d [label=\"p%d\", shape=circle, height=0.2, width=0.2];\n", [
		    indent i, Format.INT id, Format.INT(bodyName b)
		  ])
	  fun cellNd (i, id) =
		print ("%s  nd%d [label=\"\", shape=box, height=0.4, width=0.1];\n", [
		    indent i, Format.INT id
		  ])
	  fun edge (i, fromId, toId) = print ("%s  nd%d -> nd%d;\n", [
		  indent i, Format.INT fromId, Format.INT toId
		])
	  val levels = Array.array(32, [] : int list)
	  fun addNd (lvl, id) =
		Array.update(levels, lvl, id :: Array.sub(levels, lvl))
	  fun prLevels () = let
		fun loop i = (case Array.sub(levels, i)
		       of [] => ()
			| l => (
			    print ("  { rank = same;", []);
			    app (fn id => print(" nd%d;", [Format.INT id])) l;
			    print ("};\n", []);
			    loop (i+1))
		      (* end case *))
		in
		  loop 0
		end
	  fun walk (_, _, S.Empty, nextId) = nextId
	    | walk (lvl, parentId, S.Node{cell, ...}, nextId) = (
		addNd (lvl, nextId);
		edge (lvl, parentId, nextId);
		case cell
		 of (S.BodyCell b) => (bodyNd(lvl+1, nextId, b); nextId+1)
		  | (S.Cell a) => (
		      cellNd(lvl+1, nextId);
		      walkCell(lvl+1, a, nextId))
		(* end case *))
	  and walkCell (lvl, a, parentId) = let
		fun lp (i, nextId') = if (i < S.nsub)
		      then lp (i+1, walk (lvl, parentId, Array.sub(a, i), nextId'))
		      else nextId'
		in
		  lp (0, parentId+1)
		end
	  in
	    print ("digraph tree {\n", []);
            print ("  rankdir = LR;\n", []);
	    print ("  size = \"7.5,10\";\n", []);
	    print ("  ordering = out;\n", []);
	    print ("  fontsize = 8\n", []);
	    print ("  ranksep = 2\n", []);
	    case root
	     of S.Empty => ()
	      | (S.Node{cell=S.BodyCell b, ...}) => (
		  addNd (0, 0); bodyNd(0, 0, b); ())
	      | (S.Node{cell=S.Cell a, ...}) => (
		  addNd (0, 0); walkCell(1, a, 0); ())
	    (* end case *);
	    prLevels ();
	    print ("}\n", []);
	    IO.close_out strm
	  end

    fun dumpTest (fname, n) = let
	  val _ = M.srand 123
	  val data = M.testdata n
	  val S.Space{root, ...} =
		M.L.makeTree (data, V.tabulate (fn _ => ~2.0), 4.0);
	  in
	    dumpTree (fname, root, data)
	  end

  end;

