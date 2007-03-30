(* word32.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 *)

structure Word32Imp : WORD =
  struct
    infix 7 * div mod
    infix 6 + -
    infix 4 > < >= <=

    structure W32 = InlineT.Word32

    type word = Word32.word

    val wordSize = 32

    val toLargeWord   : word -> LargeWord.word = W32.toLargeWord
    val toLargeWordX  : word -> LargeWord.word = W32.toLargeWordX
    val fromLargeWord : LargeWord.word -> word = W32.fromLargeWord

    val toLargeInt    = W32.toLargeInt
    val toLargeIntX   = W32.toLargeIntX
    val fromLargeInt  = W32.fromLargeInt

    val toInt   : word -> int = W32.toInt
    val toIntX  : word -> int = W32.toIntX
    val fromInt : int -> word = W32.fromInt

    val orb  : word * word -> word = W32.orb
    val xorb : word * word -> word = W32.xorb
    val andb : word * word -> word = W32.andb
    val notb : word -> word = W32.notb

    val op * : word * word -> word = W32.*
    val op + : word * word -> word = W32.+
    val op - : word * word -> word = W32.-
    val op div : word * word -> word = W32.div
    val op mod : word * word -> word = W32.mod

    fun compare (w1, w2) =
	  if (W32.<(w1, w2)) then LESS
	  else if (W32.>(w1, w2)) then GREATER
	  else EQUAL
    val op > : word * word -> bool = W32.>
    val op >= : word * word -> bool = W32.>=
    val op < : word * word -> bool = W32.<
    val op <= : word * word -> bool = W32.<=

    val <<   = W32.chkLshift
    val >>   = W32.chkRshiftl
    val ~>>  = W32.chkRshift 

    val min : word * word -> word = W32.min
    val max : word * word -> word = W32.max

    val fmt = NumFormat.fmtWord
    val toString = fmt StringCvt.HEX

    val scan = NumScan.scanWord
    val fromString = PreBasis.scanString (scan StringCvt.HEX)

  end  (* structure Word32 *)


