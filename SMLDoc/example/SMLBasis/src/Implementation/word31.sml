(* word31.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 *)

structure Word31Imp : WORD =
  struct
    infix 7 * div mod
    infix 6 + -
    infix 4 > < >= <=

    structure W31 = InlineT.Word31
    structure LW = Word32

    type word = word

    val wordSize = 31

    val toLargeWord   : word -> LargeWord.word = W31.toLargeWord
    val toLargeWordX : word -> LargeWord.word = W31.toLargeWordX
    val fromLargeWord : LargeWord.word -> word = W31.fromLargeWord

    val toLargeInt : word -> LargeInt.int = W31.toLargeInt
    val toLargeIntX  : word -> LargeInt.int = W31.toLargeIntX
    val fromLargeInt : LargeInt.int -> word = W31.fromLargeInt

    val toInt   : word -> int = W31.toInt
    val toIntX  : word -> int = W31.toIntX
    val fromInt : int -> word = W31.fromInt

    val orb  : word * word -> word = W31.orb
    val xorb : word * word -> word = W31.xorb
    val andb : word * word -> word = W31.andb
    val notb : word -> word = W31.notb

    val op * : word * word -> word = W31.*
    val op + : word * word -> word = W31.+
    val op - : word * word -> word = W31.-
    val op div : word * word -> word = W31.div
    val op mod : word * word -> word = W31.mod

    val <<  : word * word -> word = W31.chkLshift
    val >>  : word * word -> word = W31.chkRshiftl
    val ~>> : word * word -> word = W31.chkRshift

    fun compare (w1, w2) =
	  if (W31.<(w1, w2)) then LESS
	  else if (W31.>(w1, w2)) then GREATER
	  else EQUAL
    val op > : word * word -> bool = W31.>
    val op >= : word * word -> bool = W31.>=
    val op < : word * word -> bool = W31.<
    val op <= : word * word -> bool = W31.<=

    val min : word * word -> word = W31.min
    val max : word * word -> word = W31.max

    fun fmt radix = (NumFormat.fmtWord radix) o  W31.toLargeWord
    val toString = fmt StringCvt.HEX

    fun scan radix = let
	  val scanLarge = NumScan.scanWord radix
	  fun scan getc cs = (case (scanLarge getc cs)
		 of NONE => NONE
		  | (SOME(w, cs')) => if InlineT.Word32.>(w, 0wx7FFFFFFF)
		      then raise Overflow
		      else SOME(W31.fromLargeWord w, cs')
		(* end case *))
	  in
	    scan
	  end
    val fromString = PreBasis.scanString (scan StringCvt.HEX)

  end  (* structure Word31 *)


