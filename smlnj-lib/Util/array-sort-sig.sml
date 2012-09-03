(* array-sort-sig.sml
 *
 * COPYRIGHT (c) 1993 by AT&T Bell Laboratories.  See COPYRIGHT file for details.
 *
 * Signature for in-place sorting of polymorphic arrays
 *
 *)

signature ARRAY_SORT =
  sig

    type 'a array

    val sort   : ('a * 'a -> order) -> 'a array -> unit
    val sorted : ('a * 'a -> order) -> 'a array -> bool

  end (* ARRAY_SORT *)

