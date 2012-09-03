(* char-map.sml
 *
 * COPYRIGHT (c) 1994 by AT&T Bell Laboratories.  See COPYRIGHT file for details.
 *
 * Fast, read-only, maps from characters to values.
 *
 * AUTHOR:  John Reppy
 *	    AT&T Bell Laboratories
 *	    Murray Hill, NJ 07974
 *	    jhr@research.att.com
 *)

structure CharMap :> CHAR_MAP =
  struct

  (* a finite map from characters to 'a *)
    type 'a char_map = 'a Vector.vector

  (* make a character map which maps the bound characters to their
   * bindings and maps everything else to the default value.
   *)
    fun mkCharMap {default, bindings} = let
	  val valMap = Vector.fromList(default :: (map #2 bindings))
	(* this array maps characters to indices in the valMap *)
(** NOTE: once we have Wright's value restriction, this can use the array
 ** to directly represent the char_map.
 **)
	  val arr = Array.array (Char.maxOrd, 0)
	  fun doBinding ([], _) = ()
	    | doBinding ((s, _)::r, idx) = let
		fun doChar [] = ()
		  | doChar (c::r) = (Array.update(arr, Char.ord c, idx); doChar r)
		in
		  doChar (explode s); doBinding (r, idx+1)
		end
	  in
	    doBinding (bindings, 1);
	    Vector.tabulate (
	      Char.maxOrd,
	      fn i => Vector.sub(valMap, Array.sub(arr, i)))
	  end

  (* map the given character ordinal *)
    fun mapChr cm i = Vector.sub(cm, Char.ord i)

  (* (mapStrChr c (s, i)) is equivalent to (mapChr c (String.sub(s, i))) *)
    fun mapStrChr cm (s, i) = Vector.sub(cm, Char.ord(String.sub(s, i)))

  end (* CharMap *)

