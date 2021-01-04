(* list-mergesort.sml
 *
 * COPYRIGHT (c) 2014 The Fellowship of SML/NJ (http://www.smlnj.org)
 * All rights reserved.
 *)

structure ListMergeSort : LIST_SORT = 
  struct

  (* Given a ">" relation, sort the list into increasing order.  This sort
   * detects initial increasing and decreasing runs and thus is linear
   * time on ordered input.
   *)
    fun sort gt = let
	  fun revAppend ([], ys) = ys
	    | revAppend (x::xs, ys) = revAppend(xs, x::ys)
	  fun merge ([], ys, acc) = revAppend(acc, ys)
	    | merge (xs, [], acc) = revAppend(acc, xs)
	    | merge (xs as (x::xr), ys as (y::yr), acc) =
		if gt(x, y)
		  then merge (xs, yr, y::acc)
		  else merge (xr, ys, x::acc)
	  fun mergeNeighbors ([], yss) = finishPass yss
	    | mergeNeighbors ([xs], yss) = finishPass (xs::yss)
	    | mergeNeighbors (xs1::xs2::xss, yss) =
		mergeNeighbors (xss, merge(xs1, xs2, [])::yss)
	  and finishPass [] = []
	    | finishPass [xs] = xs
	    | finishPass xss = mergeNeighbors (xss, [])
	  fun init (prev, [], yss) = mergeNeighbors ([prev]::yss, [])
	    | init (prev, x::xs, yss) = if gt(prev, x)
		then runDn (x, xs, [prev], yss)
		else runUp (x, xs, [prev], yss)
	  and runUp (prev, [], run, yss) = mergeNeighbors (revAppend(prev::run, [])::yss, [])
	    | runUp (prev, x::xr, run, yss) =
		if gt(prev, x)
		  then init (x, xr, revAppend(prev::run, [])::yss)
		  else runUp (x, xr, prev::run, yss)
	  and runDn (prev, [], run, yss) = mergeNeighbors ((prev::run)::yss, [])
	    | runDn (prev, x::xr, run, yss) =
		if gt(x, prev)
		  then init (x, xr, (prev::run)::yss)
		  else runDn (x, xr, prev::run, yss)
	  in
	    fn [] => [] | (x::xs) => init(x, xs, [])
	  end

  (* Given a comparison function, sort the sequence in ascending order while eliminating
   * duplicates.  This sort detects initial increasing and decreasing runs and thus is linear
   * time on ordered input.
   *)
    fun uniqueSort cmp = let
	  fun revAppend ([], ys) = ys
	    | revAppend (x::xs, ys) = revAppend(xs, x::ys)
	  fun merge ([], ys, acc) = revAppend(acc, ys)
	    | merge (xs, [], acc) = revAppend(acc, xs)
	    | merge (xs as (x::xr), ys as (y::yr), acc) = (
		case cmp (x, y)
		 of LESS => merge (xr, ys, x::acc)
		  | EQUAL => merge (xr, yr, x::acc)  (* discard duplicate *)
		  | GREATER => merge (xs, yr, y::acc)
		(* end case *))
	  fun mergeNeighbors ([], yss) = finishPass yss
	    | mergeNeighbors ([xs], yss) = finishPass (xs::yss)
	    | mergeNeighbors (xs1::xs2::xss, yss) =
		mergeNeighbors (xss, merge(xs1, xs2, [])::yss)
	  and finishPass [] = []
	    | finishPass [xs] = xs
	    | finishPass xss = mergeNeighbors (xss, [])
	  fun init (prev, [], yss) = mergeNeighbors ([prev]::yss, [])
	    | init (prev, x::xs, yss) = (case cmp(prev, x)
		 of LESS => runUp (x, xs, [prev], yss)
		  | EQUAL => init (prev, xs, yss) (* discard duplicate *)
		  | GREATER => runDn (x, xs, [prev], yss)
		(* end case *))
	  and runUp (prev, [], run, yss) = mergeNeighbors (revAppend(prev::run, [])::yss, [])
	    | runUp (prev, x::xr, run, yss) = (case cmp (prev, x)
		 of LESS => runUp (x, xr, prev::run, yss)
		  | EQUAL => runUp (prev, xr, run, yss) (* discard duplicate *)
		  | GREATER => init (x, xr, revAppend(prev::run, [])::yss)
		(* end case *))
	  and runDn (prev, [], run, yss) = mergeNeighbors ((prev::run)::yss, [])
	    | runDn (prev, x::xr, run, yss) = (case cmp (prev, x)
		 of LESS => init (x, xr, (prev::run)::yss)
		  | EQUAL => runDn (prev, xr, run, yss) (* discard duplicate *)
		  | GREATER => runDn (x, xr, prev::run, yss)
		(* end case *))
	  in
	    fn [] => [] | (x::xs) => init(x, xs, [])
	  end

  (* is the list sorted in ascending order according to the given ">" relation? *)
    fun sorted (op >) = let
	  fun chk (_, []) = true
	    | chk (x1, x2::xs) = not(x1>x2) andalso chk(x2, xs)
	  in
	    fn [] => true
	     | (x::xs) => chk(x, xs)
	  end

  end (* ListMergeSort *)
