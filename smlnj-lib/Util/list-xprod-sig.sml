(* list-xprod-sig.sml
 *
 * COPYRIGHT (c) 1993 by AT&T Bell Laboratories.  See COPYRIGHT file for details.
 *
 * Functions for computing with the cross product of two lists.
 *)

signature LIST_XPROD =
  sig

    val appX : (('a * 'b) -> 'c) -> ('a list * 'b list) -> unit
	(* apply a function to the cross product of two lists *)

    val mapX : (('a * 'b) -> 'c) -> ('a list * 'b list) -> 'c list
	(* map a function across the cross product of two lists *)

    val foldX : (('a * 'b * 'c) -> 'c) -> ('a list * 'b list) -> 'c -> 'c
	(* fold a function across the cross product of two lists *)

  end; (* LIST_XPROD *)
