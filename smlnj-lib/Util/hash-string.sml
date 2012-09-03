(* hash-string.sml
 *
 * COPYRIGHT (c) 1992 by AT&T Bell Laboratories
 *)

structure HashString : sig

    val hashString  : string -> word

    val hashSubstring : substring -> word

  end = struct

    fun charToWord c = Word.fromInt(Char.ord c)

  (* A function to hash a character.  The computation is:
   *
   *   h = 33 * h + 720 + c
   *)
    fun hashChar (c, h) = Word.<<(h, 0w5) + h + 0w720 + (charToWord c)

(* NOTE: another function we might try is h = 5*h + c, which is used
 * in STL.
 *)

  (* fun hashString s = CharVector.foldl hashChar 0w0 s *)
    local
      fun x + y = Word.toIntX (Word.+ (Word.fromInt x, Word.fromInt y))
      val sub = Unsafe.CharVector.sub
      fun hash (s, i0, e) = let
	    fun loop (h, i) = if i >= e
		  then h
		  else loop (hashChar (sub (s, i), h), i + 1)
	    in
	      loop (0w0, i0)
	    end
    in
    fun hashString s = hash (s, 0, size s)
    fun hashSubstring ss = let
	  val (s, i0, len) = Substring.base ss
	  in
	    hash (s, i0, i0 + len)
	  end
    end (* local *)

  end (* HashString *)
