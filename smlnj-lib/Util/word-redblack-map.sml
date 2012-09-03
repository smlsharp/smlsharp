(* word-redblack-map.sml
 *
 * COPYRIGHT (c) 2000 Bell Labs, Lucent Technologies.
 *
 * This code is based on Chris Okasaki's implementation of
 * red-black trees.  The linear-time tree construction code is
 * based on the paper "Constructing red-black trees" by Hinze,
 * and the delete function is based on the description in Cormen,
 * Leiserson, and Rivest.
 *
 * A red-black tree should satisfy the following two invariants:
 *
 *   Red Invariant: each red node has a black parent.
 *
 *   Black Condition: each path from the root to an empty node has the
 *     same number of black nodes (the tree's black height).
 *
 * The Red condition implies that the root is always black and the Black
 * condition implies that any node with only one child will be black and
 * its child will be a red leaf.
 *)

structure WordRedBlackMap :> ORD_MAP where type Key.ord_key = word =
  struct

    structure Key =
      struct
	type ord_key = word
	val compare = Word.compare
      end

    datatype color = R | B
    and 'a tree
      = E
      | T of (color * 'a tree * word * 'a * 'a tree)

    datatype 'a map = MAP of (int * 'a tree)

    fun isEmpty (MAP(_, E)) = true
      | isEmpty _ = false

    val empty = MAP(0, E)

    fun singleton (xk, x) = MAP(1, T(R, E, xk, x, E))

    fun insert (MAP(nItems, m), xk, x) = let
	  val nItems' = ref nItems
	  fun ins E = (nItems' := nItems+1; T(R, E, xk, x, E))
            | ins (s as T(color, a, yk, y, b)) =
		if (xk < yk)
		  then (case a
		     of T(R, c, zk, z, d) =>
			  if (xk < zk)
			    then (case ins c
			       of T(R, e, wk, w, f) =>
				    T(R, T(B,e,wk,w,f), zk, z, T(B,d,yk,y,b))
                		| c => T(B, T(R,c,zk,z,d), yk, y, b)
			      (* end case *))
			  else if (xk = zk)
			    then T(color, T(R, c, xk, x, d), yk, y, b)
			    else (case ins d
			       of T(R, e, wk, w, f) =>
				    T(R, T(B,c,zk,z,e), wk, w, T(B,f,yk,y,b))
                		| d => T(B, T(R,c,zk,z,d), yk, y, b)
			      (* end case *))
		      | _ => T(B, ins a, yk, y, b)
		    (* end case *))
		else if (xk = yk)
		  then T(color, a, xk, x, b)
		  else (case b
		     of T(R, c, zk, z, d) =>
			  if (xk < zk)
			    then (case ins c
			       of T(R, e, wk, w, f) =>
				    T(R, T(B,a,yk,y,e), wk, w, T(B,f,zk,z,d))
				| c => T(B, a, yk, y, T(R,c,zk,z,d))
			      (* end case *))
			  else if (xk = zk)
			    then T(color, a, yk, y, T(R, c, xk, x, d))
			    else (case ins d
			       of T(R, e, wk, w, f) =>
				    T(R, T(B,a,yk,y,c), zk, z, T(B,e,wk,w,f))
				| d => T(B, a, yk, y, T(R,c,zk,z,d))
			      (* end case *))
		      | _ => T(B, a, yk, y, ins b)
		    (* end case *))
	  val m = ins m
	  in
	    MAP(!nItems', m)
	  end
    fun insert' ((xk, x), m) = insert (m, xk, x)

  (* Is a key in the domain of the map? *)
    fun inDomain (MAP(_, t), k) = let
	  fun find' E = false
	    | find' (T(_, a, yk, y, b)) =
		(k = yk) orelse ((k < yk) andalso find' a) orelse (find' b)
	  in
	    find' t
	  end

  (* Look for an item, return NONE if the item doesn't exist *)
    fun find (MAP(_, t), k) = let
	  fun find' E = NONE
	    | find' (T(_, a, yk, y, b)) =
		if (k < yk)
		  then  find' a
		else if (k = yk)
		  then SOME y
		  else find' b
	  in
	    find' t
	  end

  (* Look for an item, raise NotFound if the item doesn't exist *)
    fun lookup (MAP(_, t), k) = let
	  fun look E = raise LibBase.NotFound
	    | look (T(_, a, yk, y, b)) =
		if (k < yk)
		  then  look a
		else if (k = yk)
		  then y
		  else look b
	  in
	    look t
	  end

  (* Remove an item, returning new map and value removed.
   * Raises LibBase.NotFound if not found.
   *)
    local
      datatype 'a zipper
	= TOP
	| LEFT of (color * word * 'a * 'a tree * 'a zipper)
	| RIGHT of (color * 'a tree * word * 'a * 'a zipper)
    in
    fun remove (MAP(nItems, t), k) = let
	  fun zip (TOP, t) = t
	    | zip (LEFT(color, xk, x, b, z), a) = zip(z, T(color, a, xk, x, b))
	    | zip (RIGHT(color, a, xk, x, z), b) = zip(z, T(color, a, xk, x, b))
	(* bbZip propagates a black deficit up the tree until either the top
	 * is reached, or the deficit can be covered.  It returns a boolean
	 * that is true if there is still a deficit and the zipped tree.
	 *)
	  fun bbZip (TOP, t) = (true, t)
	    | bbZip (LEFT(B, xk, x, T(R, c, yk, y, d), z), a) = (* case 1L *)
		bbZip (LEFT(R, xk, x, c, LEFT(B, yk, y, d, z)), a)
	    | bbZip (LEFT(color, xk, x, T(B, T(R, c, yk, y, d), wk, w, e), z), a) =
	      (* case 3L *)
		bbZip (LEFT(color, xk, x, T(B, c, yk, y, T(R, d, wk, w, e)), z), a)
	    | bbZip (LEFT(color, xk, x, T(B, c, yk, y, T(R, d, wk, w, e)), z), a) =
	      (* case 4L *)
		(false, zip (z, T(color, T(B, a, xk, x, c), yk, y, T(B, d, wk, w, e))))
	    | bbZip (LEFT(R, xk, x, T(B, c, yk, y, d), z), a) = (* case 2L *)
		(false, zip (z, T(B, a, xk, x, T(R, c, yk, y, d))))
	    | bbZip (LEFT(B, xk, x, T(B, c, yk, y, d), z), a) = (* case 2L *)
		bbZip (z, T(B, a, xk, x, T(R, c, yk, y, d)))
	    | bbZip (RIGHT(color, T(R, c, yk, y, d), xk, x, z), b) = (* case 1R *)
		bbZip (RIGHT(R, d, xk, x, RIGHT(B, c, yk, y, z)), b)
	    | bbZip (RIGHT(color, T(B, T(R, c, wk, w, d), yk, y, e), xk, x, z), b) =
	      (* case 3R *)
		bbZip (RIGHT(color, T(B, c, wk, w, T(R, d, yk, y, e)), xk, x, z), b)
	    | bbZip (RIGHT(color, T(B, c, yk, y, T(R, d, wk, w, e)), xk, x, z), b) =
	      (* case 4R *)
		(false, zip (z, T(color, c, yk, y, T(B, T(R, d, wk, w, e), xk, x, b))))
	    | bbZip (RIGHT(R, T(B, c, yk, y, d), xk, x, z), b) = (* case 2R *)
		(false, zip (z, T(B, T(R, c, yk, y, d), xk, x, b)))
	    | bbZip (RIGHT(B, T(B, c, yk, y, d), xk, x, z), b) = (* case 2R *)
		bbZip (z, T(B, T(R, c, yk, y, d), xk, x, b))
	    | bbZip (z, t) = (false, zip(z, t))
	  fun delMin (T(R, E, yk, y, b), z) = (yk, y, (false, zip(z, b)))
	    | delMin (T(B, E, yk, y, b), z) = (yk, y, bbZip(z, b))
	    | delMin (T(color, a, yk, y, b), z) = delMin(a, LEFT(color, yk, y, b, z))
	    | delMin (E, _) = raise Match
	  fun join (R, E, E, z) = zip(z, E)
	    | join (_, a, E, z) = #2(bbZip(z, a))	(* color = black *)
	    | join (_, E, b, z) = #2(bbZip(z, b))	(* color = black *)
	    | join (color, a, b, z) = let
		val (xk, x, (needB, b')) = delMin(b, TOP)
		in
		  if needB
		    then #2(bbZip(z, T(color, a, xk, x, b')))
		    else zip(z, T(color, a, xk, x, b'))
		end
	  fun del (E, z) = raise LibBase.NotFound
	    | del (T(color, a, yk, y, b), z) =
		if (k < yk)
		  then del (a, LEFT(color, yk, y, b, z))
		else if (k = yk)
		  then (y, join (color, a, b, z))
		  else del (b, RIGHT(color, a, yk, y, z))
	  val (item, t) = del(t, TOP)
	  in
	    (MAP(nItems-1, t), item)
	  end
    end (* local *)

  (* return the first item in the map (or NONE if it is empty) *)
    fun first (MAP(_, t)) = let
	  fun f E = NONE
	    | f (T(_, E, _, x, _)) = SOME x
	    | f (T(_, a, _, _, _)) = f a
	  in
	    f t
	  end
    fun firsti (MAP(_, t)) = let
	  fun f E = NONE
	    | f (T(_, E, xk, x, _)) = SOME(xk, x)
	    | f (T(_, a, _, _, _)) = f a
	  in
	    f t
	  end

  (* Return the number of items in the map *)
    fun numItems (MAP(n, _)) = n

    fun foldl f = let
	  fun foldf (E, accum) = accum
	    | foldf (T(_, a, _, x, b), accum) =
		foldf(b, f(x, foldf(a, accum)))
	  in
	    fn init => fn (MAP(_, m)) => foldf(m, init)
	  end
    fun foldli f = let
	  fun foldf (E, accum) = accum
	    | foldf (T(_, a, xk, x, b), accum) =
		foldf(b, f(xk, x, foldf(a, accum)))
	  in
	    fn init => fn (MAP(_, m)) => foldf(m, init)
	  end

    fun foldr f = let
	  fun foldf (E, accum) = accum
	    | foldf (T(_, a, _, x, b), accum) =
		foldf(a, f(x, foldf(b, accum)))
	  in
	    fn init => fn (MAP(_, m)) => foldf(m, init)
	  end
    fun foldri f = let
	  fun foldf (E, accum) = accum
	    | foldf (T(_, a, xk, x, b), accum) =
		foldf(a, f(xk, x, foldf(b, accum)))
	  in
	    fn init => fn (MAP(_, m)) => foldf(m, init)
	  end

    fun listItems m = foldr (op ::) [] m
    fun listItemsi m = foldri (fn (xk, x, l) => (xk, x)::l) [] m

  (* return an ordered list of the keys in the map. *)
    fun listKeys m = foldri (fn (k, _, l) => k::l) [] m

  (* functions for walking the tree while keeping a stack of parents
   * to be visited.
   *)
    fun next ((t as T(_, _, _, _, b))::rest) = (t, left(b, rest))
      | next _ = (E, [])
    and left (E, rest) = rest
      | left (t as T(_, a, _, _, _), rest) = left(a, t::rest)
    fun start m = left(m, [])

  (* given an ordering on the map's range, return an ordering
   * on the map.
   *)
    fun collate cmpRng = let
	  fun cmp (t1, t2) = (case (next t1, next t2)
		 of ((E, _), (E, _)) => EQUAL
		  | ((E, _), _) => LESS
		  | (_, (E, _)) => GREATER
		  | ((T(_, _, xk, x, _), r1), (T(_, _, yk, y, _), r2)) =>
		      if (xk = yk)
			then (case cmpRng(x, y)
			   of EQUAL => cmp (r1, r2)
			    | order => order
			  (* end case *))
		      else if (xk < yk)
			then LESS
			else GREATER
		(* end case *))
	  in
	    fn (MAP(_, m1), MAP(_, m2)) => cmp (start m1, start m2)
	  end

  (* support for constructing red-black trees in linear time from increasing
   * ordered sequences (based on a description by R. Hinze).  Note that the
   * elements in the digits are ordered with the largest on the left, whereas
   * the elements of the trees are ordered with the largest on the right.
   *)
    datatype 'a digit
      = ZERO
      | ONE of (word * 'a * 'a tree * 'a digit)
      | TWO of (word * 'a * 'a tree * word * 'a * 'a tree * 'a digit)
  (* add an item that is guaranteed to be larger than any in l *)
    fun addItem (ak, a, l) = let
	  fun incr (ak, a, t, ZERO) = ONE(ak, a, t, ZERO)
	    | incr (ak1, a1, t1, ONE(ak2, a2, t2, r)) =
		TWO(ak1, a1, t1, ak2, a2, t2, r)
	    | incr (ak1, a1, t1, TWO(ak2, a2, t2, ak3, a3, t3, r)) =
		ONE(ak1, a1, t1, incr(ak2, a2, T(B, t3, ak3, a3, t2), r))
	  in
	    incr(ak, a, E, l)
	  end
  (* link the digits into a tree *)
    fun linkAll t = let
	  fun link (t, ZERO) = t
	    | link (t1, ONE(ak, a, t2, r)) = link(T(B, t2, ak, a, t1), r)
	    | link (t, TWO(ak1, a1, t1, ak2, a2, t2, r)) =
		link(T(B, T(R, t2, ak2, a2, t1), ak1, a1, t), r)
	  in
	    link (E, t)
	  end

    local
      fun wrap f (MAP(_, m1), MAP(_, m2)) = let
	    val (n, result) = f (start m1, start m2, 0, ZERO)
	    in
	      MAP(n, linkAll result)
	    end
      fun ins ((E, _), n, result) = (n, result)
	| ins ((T(_, _, xk, x, _), r), n, result) =
	    ins(next r, n+1, addItem(xk, x, result))
    in

  (* return a map whose domain is the union of the domains of the two input
   * maps, using the supplied function to define the map on elements that
   * are in both domains.
   *)
    fun unionWith mergeFn = let
	  fun union (t1, t2, n, result) = (case (next t1, next t2)
		 of ((E, _), (E, _)) => (n, result)
		  | ((E, _), t2) => ins(t2, n, result)
		  | (t1, (E, _)) => ins(t1, n, result)
		  | ((T(_, _, xk, x, _), r1), (T(_, _, yk, y, _), r2)) =>
		      if (xk < yk)
			then union (r1, t2, n+1, addItem(xk, x, result))
		      else if (xk = yk)
			then union (r1, r2, n+1, addItem(xk, mergeFn(x, y), result))
			else union (t1, r2, n+1, addItem(yk, y, result))
		(* end case *))
	  in
	    wrap union
	  end
    fun unionWithi mergeFn = let
	  fun union (t1, t2, n, result) = (case (next t1, next t2)
		 of ((E, _), (E, _)) => (n, result)
		  | ((E, _), t2) => ins(t2, n, result)
		  | (t1, (E, _)) => ins(t1, n, result)
		  | ((T(_, _, xk, x, _), r1), (T(_, _, yk, y, _), r2)) =>
		      if (xk < yk)
			then union (r1, t2, n+1, addItem(xk, x, result))
		      else if (xk = yk)
			then
			  union (r1, r2, n+1, addItem(xk, mergeFn(xk, x, y), result))
			else union (t1, r2, n+1, addItem(yk, y, result))
		(* end case *))
	  in
	    wrap union
	  end

  (* return a map whose domain is the intersection of the domains of the
   * two input maps, using the supplied function to define the range.
   *)
    fun intersectWith mergeFn = let
	  fun intersect (t1, t2, n, result) = (case (next t1, next t2)
		 of ((T(_, _, xk, x, _), r1), (T(_, _, yk, y, _), r2)) =>
		      if (xk < yk)
			then intersect (r1, t2, n, result)
		      else if (xk = yk)
			then intersect (
			  r1, r2, n+1, addItem(xk, mergeFn(x, y), result))
			else intersect (t1, r2, n, result)
		  | _ => (n, result)
		(* end case *))
	  in
	    wrap intersect
	  end
    fun intersectWithi mergeFn = let
	  fun intersect (t1, t2, n, result) = (case (next t1, next t2)
		 of ((T(_, _, xk, x, _), r1), (T(_, _, yk, y, _), r2)) =>
		      if (xk < yk)
			then intersect (r1, t2, n, result)
		      else if (xk = yk)
			then intersect (r1, r2, n+1,
			  addItem(xk, mergeFn(xk, x, y), result))
			else intersect (t1, r2, n, result)
		  | _ => (n, result)
		(* end case *))
	  in
	    wrap intersect
	  end

    fun mergeWith mergeFn = let
	  fun merge (t1, t2, n, result) = (case (next t1, next t2)
		 of ((E, _), (E, _)) => (n, result)
		  | ((E, _), (T(_, _, yk, y, _), r2)) =>
		      mergef(yk, NONE, SOME y, t1, r2, n, result)
		  | ((T(_, _, xk, x, _), r1), (E, _)) =>
		      mergef(xk, SOME x, NONE, r1, t2, n, result)
		  | ((T(_, _, xk, x, _), r1), (T(_, _, yk, y, _), r2)) =>
		      if (xk  < yk)
			then mergef(xk, SOME x, NONE, r1, t2, n, result)
		      else if (xk = yk)
			then mergef(xk, SOME x, SOME y, r1, r2, n, result)
			else mergef(yk, NONE, SOME y, t1, r2, n, result)
		(* end case *))
	  and mergef (k, x1, x2, r1, r2, n, result) = (case mergeFn(x1, x2)
		 of NONE => merge (r1, r2, n, result)
		  | SOME y => merge (r1, r2, n+1, addItem(k, y, result))
		(* end case *))
	  in
	    wrap merge
	  end
    fun mergeWithi mergeFn = let
	  fun merge (t1, t2, n, result) = (case (next t1, next t2)
		 of ((E, _), (E, _)) => (n, result)
		  | ((E, _), (T(_, _, yk, y, _), r2)) =>
		      mergef(yk, NONE, SOME y, t1, r2, n, result)
		  | ((T(_, _, xk, x, _), r1), (E, _)) =>
		      mergef(xk, SOME x, NONE, r1, t2, n, result)
		  | ((T(_, _, xk, x, _), r1), (T(_, _, yk, y, _), r2)) =>
		      if (xk  < yk)
			then mergef(xk, SOME x, NONE, r1, t2, n, result)
		      else if (xk = yk)
			then mergef(xk, SOME x, SOME y, r1, r2, n, result)
			else mergef(yk, NONE, SOME y, t1, r2, n, result)
		(* end case *))
	  and mergef (k, x1, x2, r1, r2, n, result) = (case mergeFn(k, x1, x2)
		 of NONE => merge (r1, r2, n, result)
		  | SOME y => merge (r1, r2, n+1, addItem(k, y, result))
		(* end case *))
	  in
	    wrap merge
	  end
    end (* local *)

    fun app f = let
	  fun appf E = ()
	    | appf (T(_, a, _, x, b)) = (appf a; f x; appf b)
	  in
	    fn (MAP(_, m)) => appf m
	  end
    fun appi f = let
	  fun appf E = ()
	    | appf (T(_, a, xk, x, b)) = (appf a; f(xk, x); appf b)
	  in
	    fn (MAP(_, m)) => appf m
	  end

    fun map f = let
	  fun mapf E = E
	    | mapf (T(color, a, xk, x, b)) =
		T(color, mapf a, xk, f x, mapf b)
	  in
	    fn (MAP(n, m)) => MAP(n, mapf m)
	  end
    fun mapi f = let
	  fun mapf E = E
	    | mapf (T(color, a, xk, x, b)) =
		T(color, mapf a, xk, f(xk, x), mapf b)
	  in
	    fn (MAP(n, m)) => MAP(n, mapf m)
	  end

  (* Filter out those elements of the map that do not satisfy the
   * predicate.  The filtering is done in increasing map order.
   *)
    fun filter pred (MAP(_, t)) = let
	  fun walk (E, n, result) = (n, result)
	    | walk (T(_, a, xk, x, b), n, result) = let
		val (n, result) = walk(a, n, result)
		in
		  if (pred x)
		    then walk(b, n+1, addItem(xk, x, result))
		    else walk(b, n, result)
		end
	  val (n, result) = walk (t, 0, ZERO)
	  in
	    MAP(n, linkAll result)
	  end
    fun filteri pred (MAP(_, t)) = let
	  fun walk (E, n, result) = (n, result)
	    | walk (T(_, a, xk, x, b), n, result) = let
		val (n, result) = walk(a, n, result)
		in
		  if (pred(xk, x))
		    then walk(b, n+1, addItem(xk, x, result))
		    else walk(b, n, result)
		end
	  val (n, result) = walk (t, 0, ZERO)
	  in
	    MAP(n, linkAll result)
	  end

  (* map a partial function over the elements of a map in increasing
   * map order.
   *)
    fun mapPartial f = let
	  fun f' (xk, x, m) = (case f x
		 of NONE => m
		  | (SOME y) => insert(m, xk, y)
		(* end case *))
	  in
	    foldli f' empty
	  end
    fun mapPartiali f = let
	  fun f' (xk, x, m) = (case f(xk, x)
		 of NONE => m
		  | (SOME y) => insert(m, xk, y)
		(* end case *))
	  in
	    foldli f' empty
	  end

  end;
