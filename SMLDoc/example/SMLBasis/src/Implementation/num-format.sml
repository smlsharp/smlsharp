(* num-format.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * The word to string conversion for the largest word and int types.
 * All of the other fmt functions can be implemented in terms of them.
 *
 *)

structure NumFormat : sig

    val fmtWord : StringCvt.radix -> Word32.word -> string
    val fmtInt  : StringCvt.radix -> Int32.int -> string

  end = struct

    structure W = InlineT.Word32
    structure I = InlineT.Int31
    structure I32 = InlineT.Int32

    val op < = W.<
    val op - = W.-
    val op * = W.*
    val op div = W.div

    fun mkDigit (w : Word32.word) =
	  InlineT.CharVector.sub("0123456789abcdef", W.toInt w)

    fun wordToBin w = let
	  fun mkBit w = if (W.andb(w, 0w1) = 0w0) then #"0" else #"1"
	  fun f (0w0, n, l) = (I.+(n, 1), #"0" :: l)
	    | f (0w1, n, l) = (I.+(n, 1), #"1" :: l)
	    | f (w, n, l) = f(W.rshiftl(w, 0w1), I.+(n, 1), (mkBit w) :: l)
	  in
	    f (w, 0, [])
	  end
    fun wordToOct w = let
	  fun f (w, n, l) = if (w < 0w8)
		then (I.+(n, 1), (mkDigit w) :: l)
		else f(W.rshiftl(w, 0w3), I.+(n, 1), mkDigit(W.andb(w, 0wx7)) :: l)
	  in
	    f (w, 0, [])
	  end
    fun wordToDec w = let
	  fun f (w, n, l) = if (w < 0w10)
		then (I.+(n, 1), (mkDigit w) :: l)
		else let val j = w div 0w10
		  in
		    f (j,  I.+(n, 1), mkDigit(w - 0w10*j) :: l)
		  end
	  in
	    f (w, 0, [])
	  end
    fun wordToHex w = let
	  fun f (w, n, l) = if (w < 0w16)
		then (I.+(n, 1), (mkDigit w) :: l)
		else f(W.rshiftl(w, 0w4), I.+(n, 1), mkDigit(W.andb(w, 0wxf)) :: l)
	  in
	    f (w, 0, [])
	  end

    fun fmtW StringCvt.BIN = wordToBin
      | fmtW StringCvt.OCT = wordToOct
      | fmtW StringCvt.DEC = wordToDec
      | fmtW StringCvt.HEX = wordToHex

    fun fmtWord radix = PreString.implode o (fmtW radix)

    val i2w = W.fromLargeInt o I32.toLarge

    fun fmtInt radix i = 
      if i2w i = 0wx80000000 then "~2147483648"
      else let
	  val w32 = i2w (if I32.<(i, 0) then I32.~(i) else i)
          val (n, digits) = fmtW radix w32
	in
	  if I32.<(i, 0) then PreString.implode(I.+(n,1), #"~"::digits)
	  else PreString.implode(n, digits)
	end
  end;


