(* word8.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 *)

structure Word8Imp : WORD =
  struct

    structure W8 = InlineT.Word8
    structure W31 = InlineT.Word31
    structure LW = Word32Imp

    type word = Word8.word		(* 31 bits *)

    val wordSize = 8
    val wordSizeW = 0w8
    val wordShift = InlineT.Word31.-(0w31, wordSizeW)
    fun adapt oper args = W8.andb(oper args, 0wxFF)

    val toInt   : word -> int = W8.toInt
    val toIntX  : word -> int = W8.toIntX
    val fromInt : int -> word = W8.fromInt

    val toLargeWord : word -> LargeWord.word = W8.toLargeWord
    val toLargeWordX = W8.toLargeWordX
    val fromLargeWord = W8.fromLargeWord

    val toLargeInt  : word -> LargeInt.int = LW.toLargeInt o toLargeWord
    val toLargeIntX : word -> LargeInt.int = W8.toLargeIntX
    val fromLargeInt: LargeInt.int -> word = W8.fromLargeInt


  (** These should be inline functions **)
    fun << (w : word, k) = if (InlineT.DfltWord.<=(wordSizeW, k))
	  then 0w0
	  else adapt W8.lshift (w, k)
    fun >> (w : word, k) = if (InlineT.DfltWord.<=(wordSizeW, k))
	  then 0w0
	  else W8.rshiftl(w, k)
    fun ~>> (w : word, k) = if (InlineT.DfltWord.<=(wordSizeW, k))
	  then adapt W8.rshift (W8.lshift(w, wordShift), 0w31)
	  else adapt W8.rshift
	    (W8.lshift(w, wordShift), InlineT.DfltWord.+(wordShift, k))

    val orb  : word * word -> word = W8.orb
    val xorb : word * word -> word = W8.xorb
    val andb : word * word -> word = W8.andb
    val notb : word -> word = adapt W8.notb

    val op * : word * word -> word = adapt W8.*
  (* NOTE: waste of time to check for overflow; really should use Word31
   * arithmetic operators; when those get implemented, switch over.
   *)
    val op + : word * word -> word = adapt W8.+
    val op - : word * word -> word = adapt W8.-
    val op div : word * word -> word = W8.div
    fun op mod (a:word, b:word):word = a-(a div b)*b

    fun compare (w1, w2) =
	  if (W8.<(w1, w2)) then LESS
	  else if (W8.>(w1, w2)) then GREATER
	  else EQUAL
    val op > : word * word -> bool = W8.>
    val op >= : word * word -> bool = W8.>=
    val op < : word * word -> bool = W8.<
    val op <= : word * word -> bool = W8.<=

    fun min (w1, w2) = if (w1 < w2) then w1 else w2
    fun max (w1, w2) = if (w1 > w2) then w1 else w2

    fun fmt radix = (NumFormat.fmtWord radix) o toLargeWord 
    val toString = fmt StringCvt.HEX

    fun scan radix = let
	  val scanLarge = NumScan.scanWord radix
	  fun scan getc cs = (case (scanLarge getc cs)
		 of NONE => NONE
		  | (SOME(w, cs')) => if InlineT.Word32.>(w, 0w255)
		      then raise Overflow
		      else SOME(fromLargeWord w, cs')
		(* end case *))
	  in
	    scan
	  end
    val fromString = PreBasis.scanString (scan StringCvt.HEX)

  end  (* structure Word8 *)


