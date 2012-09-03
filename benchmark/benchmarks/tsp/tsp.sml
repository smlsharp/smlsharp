(* tsp.sml
 *
 * COPYRIGHT (c) 1994 AT&T Bell Laboratories.
 *)

structure TSP : sig

    val tsp : (Tree.tree * int) -> Tree.tree

  end = struct

    structure T = Tree

    fun setPrev (T.ND{prev, ...}, x) = prev := x
    fun setNext (T.ND{next, ...}, x) = next := x
    fun link (a as T.ND{next, ...}, b as T.ND{prev, ...}) = (
	  next := b; prev := a)

    fun sameNd (T.ND{next, ...}, T.ND{next=next', ...}) = (next = next')
      | sameNd (T.NULL, T.NULL) = true
      | sameNd _ = false

  (* Find Euclidean distance from a to b *)
    fun distance (T.ND{x=ax, y=ay, ...}, T.ND{x=bx, y=by, ...}) =
	  Math.sqrt(((ax-bx)*(ax-bx)+(ay-by)*(ay-by)))
      | distance _ = raise Fail "distance"

  (* sling tree nodes into a list -- requires root to be tail of list, and
   * only fills in next field, not prev.
   *)
    fun makeList T.NULL = T.NULL
      | makeList (t as T.ND{left, right, next = t_next, ...}) = let
	  val retVal = (case (makeList left, makeList right)
		 of (T.NULL, T.NULL) => t
		  | (l as T.ND{...}, T.NULL) => (setNext(left, t); l)
		  | (T.NULL, r as T.ND{...}) => (setNext(right, t); r)
		  | (l as T.ND{...}, r as T.ND{...}) => (
		      setNext(right, t); setNext(left, r); l)
		(* end case *))
	  in
	    t_next := T.NULL;
	    retVal
	  end

  (* reverse orientation of list *)
    fun reverse T.NULL = ()
      | reverse (t as T.ND{next, prev, ...}) = let
	  fun rev (_, T.NULL) = ()
	    | rev (back, tmp as T.ND{prev, next, ...}) = let
		val tmp' = !next
		in
		  next := back;  setPrev(back, tmp);
		  rev (tmp, tmp')
		end
	  in
	    setNext (!prev, T.NULL);
	    prev := T.NULL;
	    rev (t, !next)
	  end

  (* Use closest-point heuristic from Cormen Leiserson and Rivest *)
    fun conquer (T.NULL) = T.NULL
      | conquer t = let
	  val (cycle as T.ND{next=cycle_next, prev=cycle_prev, ...}) = makeList t
	  fun loop (T.NULL) = ()
	    | loop (t as T.ND{next=ref doNext, prev, ...}) =
		let
		fun findMinDist (min, minDist, tmp as T.ND{next, ...}) =
		      if (sameNd(cycle, tmp))
			then min
			else let
			  val test = distance(t, tmp)
			  in
			    if (test < minDist)
			      then findMinDist (tmp, test, !next)
			      else findMinDist (min, minDist, !next)
			  end
		val (min as T.ND{next=ref min_next, prev=ref min_prev, ...}) =
			findMinDist (cycle, distance(t, cycle), !cycle_next)
		val minToNext = distance(min, min_next)
		val minToPrev = distance(min, min_prev)
		val tToNext = distance(t, min_next)
		val tToPrev = distance(t, min_prev)
		in
		  if ((tToPrev - minToPrev) < (tToNext - minToNext))
		    then ( (* insert between min and min_prev *)
		      link (min_prev, t);
		      link (t, min))
		    else (
		      link (min, t);
		      link (t, min_next));
		  loop doNext
		end
	  val t' = !cycle_next
	  in
	  (* Create initial cycle *)
	    cycle_next := cycle;  cycle_prev := cycle;
	    loop t';
	    cycle
	  end

  (* Merge two cycles as per Karp *)
    fun merge (a as T.ND{next, ...}, b, t) = let
	  fun locateCycle (start as T.ND{next, ...}) = let
		fun findMin (min, minDist, tmp as T.ND{next, ...}) =
		      if (sameNd(start, tmp))
			then (min, minDist)
			else let val test = distance(t, tmp)
			  in
			    if (test < minDist)
			      then findMin (tmp, test, !next)
			      else findMin (min, minDist, !next)
			  end
		val (min as T.ND{next=ref next', prev=ref prev', ...}, minDist) =
			findMin (start, distance(t, start), !next)
		val minToNext = distance(min, next')
		val minToPrev = distance(min, prev')
		val tToNext = distance(t, next')
		val tToPrev = distance(t, prev')
		in
		  if ((tToPrev - minToPrev) < (tToNext - minToNext))
		  (* would insert between min and prev *)
		    then (prev', tToPrev, min, minDist)
		  (* would insert between min and next *)
		    else (min, minDist, next', tToNext)
		end
	(* Compute location for first cycle *)
	  val (p1, tToP1, n1, tToN1) = locateCycle a
	(* compute location for second cycle *)
	  val (p2, tToP2, n2, tToN2) = locateCycle b
	(* Now we have 4 choices to complete:
	 *   1:t,p1 t,p2 n1,n2
	 *   2:t,p1 t,n2 n1,p2
	 *   3:t,n1 t,p2 p1,n2
	 *   4:t,n1 t,n2 p1,p2
	 *)
	  val n1ToN2 = distance(n1, n2)
	  val n1ToP2 = distance(n1, p2)
	  val p1ToN2 = distance(p1, n2)
	  val p1ToP2 = distance(p1, p2)
	  fun choose (testChoice, test, choice, minDist) =
		if (test < minDist) then (testChoice, test) else (choice, minDist)
	  val (choice, minDist) = (1, tToP1+tToP2+n1ToN2)
	  val (choice, minDist) = choose(2, tToP1+tToN2+n1ToP2, choice, minDist)
	  val (choice, minDist) = choose(3, tToN1+tToP2+p1ToN2, choice, minDist)
	  val (choice, minDist) = choose(4, tToN1+tToN2+p1ToP2, choice, minDist)
	  in
	    case choice
	     of 1 => (	(* 1:p1,t t,p2 n2,n1 -- reverse 2! *)
		  reverse n2;
		  link (p1, t);
		  link (t, p2);
		  link (n2, n1))
	      | 2 => (	(* 2:p1,t t,n2 p2,n1 -- OK *)
		  link (p1, t);
		  link (t, n2);
		  link (p2, n1))
	      | 3 => (	(* 3:p2,t t,n1 p1,n2 -- OK *)
		  link (p2, t);
		  link (t, n1);
		  link (p1, n2))
	      | 4 => (	(* 4:n1,t t,n2 p2,p1 -- reverse 1! *)
		  reverse n1;
		  link (n1, t);
		  link (t, n2);
		  link (p2, p1))
	    (* end case *);
	    t
	  end (* merge *)

  (* Compute TSP for the tree t -- use conquer for problems <= sz * *)
    fun tsp (t as T.ND{left, right, sz=sz', ...}, sz) =
	  if (sz' <= sz)
	    then conquer t
	    else merge (tsp(left, sz), tsp(right, sz), t)
      | tsp (T.NULL, _) = T.NULL

  end;

