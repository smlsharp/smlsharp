(* list-xprod.sml
 *
 * COPYRIGHT (c) 1993 by AT&T Bell Laboratories.  See COPYRIGHT file for details.
 *
 * Functions for computing with the cross product of two lists.
 *)

structure ListXProd : LIST_XPROD =
  struct

  (* apply a function to the cross product of two lists *)
    fun appX f (l1, l2) = let
	  fun lp1 [] = ()
	    | lp1 (x::r) = let
		fun lp2 [] = lp1 r
		  | lp2 (y::r) = (f(x, y); lp2 r)
		in
		  lp2 l2
		end
	  in
	    lp1 l1
	  end

  (* map a function across the cross product of two lists *)
    fun mapX f (l1, l2) = let
	  fun lp1 ([], resL) = rev resL
	    | lp1 (x::r, resL) = let
		fun lp2 ([], resL) = lp1 (r, resL)
		  | lp2 (y::r, resL) = lp2 (r, f(x, y) :: resL)
		in
		  lp2 (l2, resL)
		end
	  in
	    lp1 (l1, [])
	  end

  (* fold a function across the cross product of two lists *)
    fun foldX f (l1, l2) = let
	  fun lp1 ([], accum) = accum
	    | lp1 (x::r, accum) = let
		fun lp2 ([], accum) = lp1 (r, accum)
		  | lp2 (y::r, accum) = lp2 (r, f(x, y, accum))
		in
		  lp2 (l2, accum)
		end
	  in
	    fn init => lp1 (l1, init)
	  end

  end; (* ListXProd *)
