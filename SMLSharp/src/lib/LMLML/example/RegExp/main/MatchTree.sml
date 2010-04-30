
structure MatchTree :> MATCH_TREE =
  struct

    datatype 'a match_tree = Match of 'a * 'a match_tree list

    fun num m = 
	let fun countList [] = 0
	      | countList ((Match (x,l))::ms) = 1+countList(l)+countList(ms)
	in
	    (countList [m])-1
	end

  (* return the root (outermost) match in the tree *)
    fun root (Match (x,_)) = x

  (* return the nth match in the tree; matches are labeled in pre-order
   * starting at 0.
   *)
    fun nth (t, n) = let
	  datatype 'a sum = INL of int | INR of 'a
	  fun walk (0, Match (x, _)) = INR x
	    | walk (i, Match (_, children)) = let
		fun walkList (i, []) = INL i
		  | walkList (i, m::r) = (case walk(i, m)
		       of (INL j) => walkList (j, r)
			| result => result
		      (* end case *))
		in
		  walkList (i-1, children)
		end
	  in
	    case walk(n, t)
	     of (INR x) => x
	      | (INL _) => raise Subscript
	    (* end case *)
	  end

  (* map a function over the tree (in preorder) *)
    fun map f = let
	  fun mapf (Match (x, children)) = Match(f x, mapl children)
	  and mapl [] = []
	    | mapl (x::r) = (mapf x) :: (mapl r)
	  in
	    mapf
	  end

    fun app f (Match (c,children)) = (f c; List.app (app f) children)

  (* find the first match that satisfies the predicate *)
    fun find pred = let
	  fun findP (Match (x, children)) =
		if (pred x)
		  then SOME x
		  else findList children
	  and findList [] = NONE
	    | findList (m::r) = (case (findP m)
		 of NONE => findList r
		  | result => result
		(* end case *))
	  in
	    findP
	  end

  end (* MatchTree *)

