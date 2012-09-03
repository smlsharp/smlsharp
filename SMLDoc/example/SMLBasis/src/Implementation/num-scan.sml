(* num-scan.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * The string conversion for the largest int and word types.
 * All of the other scan functions can be implemented in terms of them.
 *
 *)

structure NumScan : sig

    val scanWord : StringCvt.radix
	  -> (char, 'a) StringCvt.reader -> (Word32.word, 'a) StringCvt.reader
    val scanInt  : StringCvt.radix
	  -> (char, 'a) StringCvt.reader -> (Int32.int, 'a) StringCvt.reader
    val scanReal : (char, 'a) StringCvt.reader -> (real, 'a) StringCvt.reader
	(** should be to LargeReal.real **)

  end = struct

    structure W = InlineT.Word32
    structure I = InlineT.Int31
    structure I32 = InlineT.Int32
    structure R = InlineT.Real64
    type word = Word32.word

    val op <  = W.<
    val op >= = W.>=
    val op +  = W.+
    val op -  = W.-
    val op *  = W.*

    val largestWordDiv10 : word = 0w429496729	(* 2^32-1 divided by 10 *)
    val largestWordMod10 : word = 0w5		(* remainder *)

    val largestNegInt32 : word = 0wx80000000
    val largestPosInt32 : word = 0wx7fffffff
    val minInt32 : Int32.int = ~2147483648

  (* A table for mapping digits to values.  Whitespace characters map to
   * 128, "+" maps to 129, "-","~" map to 130, "." maps to 131, and the
   * characters 0-9,A-Z,a-z map to their * base-36 value.  All other
   * characters map to 255.
   *)
    local
      val cvtTable = "\
	    \\255\255\255\255\255\255\255\255\255\128\128\255\255\255\255\255\
	    \\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
	    \\128\255\255\255\255\255\255\255\255\255\255\129\255\130\131\255\
	    \\000\001\002\003\004\005\006\007\008\009\255\255\255\255\255\255\
	    \\255\010\011\012\013\014\015\016\017\018\019\020\021\022\023\024\
	    \\025\026\027\028\029\030\031\255\033\034\035\255\255\255\255\255\
	    \\255\010\011\012\013\014\015\016\017\018\019\020\021\022\023\024\
	    \\025\026\027\028\029\030\031\032\033\034\035\255\255\255\130\255\
	    \\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
	    \\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
	    \\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
	    \\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
	    \\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
	    \\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
	    \\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
	    \\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
	  \"
    val ord = InlineT.Char.ord
    in
    fun code (c : char) =
	  W.fromInt(ord(InlineT.CharVector.sub(cvtTable, ord c)))
    val wsCode : word = 0w128		(* code for whitespace *)
    val plusCode : word = 0w129		(* code for #"+" *)
    val minusCode : word = 0w130	(* code for #"-" and #"~" *)
    val ptCode : word = 0w131		(* code for #"." *)
    val eCode : word = 0w14		(* code for #"e" and #"E" *)
    val wCode : word = 0w32		(* code for #"w" *)
    val xCode : word = 0w33		(* code for #"X" and #"X" *)
    end (* local *)

    type prefix_pat = {
	wOkay : bool,		(* true if 0[wW] prefix is okay; if this is
				 * true, then signs (+, -, ~) are not okay.
				 *)
	xOkay : bool,		(* true if 0[xX] prefix is okay *)
        ptOkay: bool,           (* true if can start with point *)
	isDigit : word -> bool	(* returns true for allowed digits *)
      }

    (* scanPrefix : prefix_pat -> (char,'a) reader -> 'a
                    -> {neg: bool, next: word (* code *), rest: 'a} option
       scans prefix for a number:
       binPat(true)  {wOkay=true, xOkay=false, ptOkay=false, isBinDigit} =>
	   (0[wW])?b (b binary digit)
       binPat(false) {wOkay=true, xOkay=false, ptOkay=false, isBinDigit} =>
	   [-~+]?b
       octPat(true)  {wOkay=true, xOkay=false, ptOkay=false, isOctDigit} =>
	   (0[wW])?o (o octal digit)
       octPat(false) {wOkay=false, xOkay=false, ptOkay=false, isOctDigit} =>
	   [-~+]?o
       hexPat(true)  {wOkay=true, xOkay=true, ptOkay=false, isHexDigit} =>
           (0[wW][xX])?h (h hex digit)
       hexPat(false) {wOkay=false, xOkay=true, ptOkay=false, isHexDigit} =>
	   [-~+]?(0[xX])?h
       decPat(true,false) {wOkay=true, xOkay=false, ptOkay=false, isDecDigit} =>
           (0[wW][xX])?d (d decimal digit)
       decPat(false,false){wOkay=false, xOkay=false, ptOkay=false, isDecDigit} =>
	   [-~+]?d
       decPat(false,true) {wOkay=false, xOkay=false, ptOkay=true, isDecDigit} =>
	   [-~+]?[.d]

       Sign characters, initial 0x, 0w, etc are consumed.  The initial
       digit or point code is returned as the value of next.
     *)
    fun scanPrefix (p : prefix_pat) getc cs = let
	  fun getNext cs = (case (getc cs)
		 of NONE => NONE
		  | (SOME(c, cs)) => SOME(code c, cs)
		(* end case *))
	  fun skipWS cs = (case (getNext cs)
		 of NONE => NONE
		  | (SOME(c, cs')) =>
		      if (c = wsCode) then skipWS cs' else SOME(c, cs')
		(* end case *))
	  fun getOptSign NONE = NONE
	    | getOptSign (next as SOME(c, cs)) =
		if (#wOkay p)
		  then getOpt0 (false, SOME(c, cs))
		else if (c = plusCode)
		  then getOpt0 (false, getNext cs)
		else if (c = minusCode)
		  then getOpt0 (true, getNext cs)
		  else getOpt0 (false, next)
	  and getOpt0 (neg, NONE) = NONE
	    | getOpt0 (neg, SOME(c, cs)) =
		if ((c = 0w0) andalso ((#wOkay p) orelse (#xOkay p)))
		  then getOptW (neg, (c, cs), getNext cs)
		  else finish (neg, (c, cs))
	  and getOptW (neg, savedCS, NONE) = finish (neg, savedCS)
	    | getOptW (neg, savedCS, arg as SOME(c, cs)) =
		if ((c = wCode) andalso (#wOkay p))
		  then getOptX (neg, savedCS, getNext cs)
		  else getOptX (neg, savedCS, arg)
	  and getOptX (neg, savedCS, NONE) = finish (neg, savedCS)
	    | getOptX (neg, savedCS, arg as SOME(c, cs)) =
		if ((c = xCode) andalso (#xOkay p))
		  then chkDigit (neg, savedCS, getNext cs)
		  else chkDigit (neg, savedCS, arg)
	  and chkDigit (neg, savedCS, NONE) = finish (neg, savedCS)
	    | chkDigit (neg, savedCS, SOME(c, cs)) =
		if ((#isDigit p) c)
		  then SOME{neg=neg, next = c, rest = cs}
		  else finish (neg, savedCS)
	  and finish (neg, (c, cs)) =
		if ((#isDigit p) c) orelse ((c = ptCode) andalso (#ptOkay p))
		  then SOME{neg=neg, next = c, rest = cs}
		  else NONE
	  in
	    getOptSign (skipWS cs)
	  end

  (* for power of 2 bases (2, 8 & 16), we can check for overflow by looking
   * at the hi (1, 3 or 4) bits.
   *)
    fun chkOverflow mask w =
	  if (W.andb(mask, w) = 0w0) then () else raise Overflow

    fun isBinDigit d = (d < 0w2)
    fun isOctDigit d = (d < 0w8)
    fun isDecDigit d = (d < 0w10)
    fun isHexDigit d = (d < 0w16)

    fun binPat wOkay = {wOkay=wOkay, xOkay=false, ptOkay=false, isDigit=isBinDigit}
    fun octPat wOkay = {wOkay=wOkay, xOkay=false, ptOkay=false, isDigit=isOctDigit}
    fun hexPat wOkay = {wOkay=wOkay, xOkay=true,  ptOkay=false, isDigit=isHexDigit}
    fun decPat (wOkay,ptOkay) = {wOkay=wOkay, xOkay=false, ptOkay=ptOkay,
				 isDigit=isDecDigit}

    fun scanBin isWord getc cs = (case (scanPrefix (binPat isWord) getc cs)
	   of NONE => NONE
	    | (SOME{neg, next, rest}) => let
		val chkOverflow = chkOverflow 0wx80000000
		fun cvt (w, rest) = (case (getc rest)
		       of NONE => SOME{neg=neg, word=w, rest=rest}
			| SOME(c, rest') => let val d = code c
			    in
			      if (isBinDigit d)
				then (
				  chkOverflow w;
				  cvt(W.+(W.lshift(w, 0w1), d), rest'))
				else SOME{neg=neg, word=w, rest=rest}
			    end
		      (* end case *))
		in
		  cvt (next, rest)
		end
	  (* end case *))

    fun scanOct isWord getc cs = (case (scanPrefix (octPat isWord) getc cs)
	   of NONE => NONE
	    | (SOME{neg, next, rest}) => let
		val chkOverflow = chkOverflow 0wxE0000000
		fun cvt (w, rest) = (case (getc rest)
		       of NONE => SOME{neg=neg, word=w, rest=rest}
			| SOME(c, rest') => let val d = code c
			    in
			      if (isOctDigit d)
				then (
				  chkOverflow w;
				  cvt(W.+(W.lshift(w, 0w3), d), rest'))
				else SOME{neg=neg, word=w, rest=rest}
			    end
		      (* end case *))
		in
		  cvt (next, rest)
		end
	  (* end case *))

    fun scanDec isWord getc cs = (case (scanPrefix (decPat(isWord,false)) getc cs)
	   of NONE => NONE
	    | (SOME{neg, next, rest}) => let
		fun cvt (w, rest) = (case (getc rest)
		       of NONE => SOME{neg=neg, word=w, rest=rest}
			| SOME(c, rest') => let val d = code c
			    in
			      if (isDecDigit d)
				then (
				  if ((w >= largestWordDiv10)
				  andalso ((largestWordDiv10 < w)
				    orelse (largestWordMod10 < d)))
				    then raise Overflow
				    else ();
				  cvt (0w10*w+d, rest'))
				else SOME{neg=neg, word=w, rest=rest}
			    end
		      (* end case *))
		in
		  cvt (next, rest)
		end
	  (* end case *))

    fun scanHex isWord getc cs = (case (scanPrefix (hexPat isWord) getc cs)
	   of NONE => NONE
	    | (SOME{neg, next, rest}) => let
		val chkOverflow = chkOverflow 0wxF0000000
		fun cvt (w, rest) = (case (getc rest)
		       of NONE => SOME{neg=neg, word=w, rest=rest}
			| SOME(c, rest') => let val d = code c
			    in
			      if (isHexDigit d)
				then (
				  chkOverflow w;
				  cvt(W.+(W.lshift(w, 0w4), d), rest'))
				else SOME{neg=neg, word=w, rest=rest}
			    end
		      (* end case *))
		in
		  cvt (next, rest)
		end
	  (* end case *))

    fun finalWord scanFn getc cs = (case (scanFn true getc cs)
	   of NONE => NONE
	    | (SOME{neg, word, rest}) => SOME(word, rest)
	  (* end case *))

    fun scanWord StringCvt.BIN = finalWord scanBin
      | scanWord StringCvt.OCT = finalWord scanOct
      | scanWord StringCvt.DEC = finalWord scanDec
      | scanWord StringCvt.HEX = finalWord scanHex

    local
      val fromword32 = I32.fromLarge o W.toLargeIntX 
    in
    fun finalInt scanFn getc cs = (case (scanFn false getc cs)
	   of NONE => NONE
	    | (SOME{neg=true, word, rest}) =>
		if (word < largestNegInt32) then
		   SOME(InlineT.Int32.~(fromword32 word), rest)
		else if (largestNegInt32 < word) then
		   raise Overflow
		else 
		   SOME(minInt32, rest)
	    | (SOME{word, rest, ...}) =>
		if (largestPosInt32 < word) then
		   raise Overflow
	        else 
	           SOME(fromword32 word, rest)
	  (* end case *))
    end

    fun scanInt StringCvt.BIN = finalInt scanBin
      | scanInt StringCvt.OCT = finalInt scanOct
      | scanInt StringCvt.DEC = finalInt scanDec
      | scanInt StringCvt.HEX = finalInt scanHex
  
  (* scan a string of decimal digits (starting with d), and return their
   * value as a real number.  Also return the number of digits, and the
   * rest of the stream.
   *)
    fun fscan10 getc (d, cs) = let
	  fun wordToReal w = InlineT.real(W.toIntX w)
	  fun scan (accum, n, cs) = (case (getc cs)
		 of (SOME(c, cs')) => let val d = code c
		      in
			if (isDecDigit d)
			  then scan(R.+(R.*(10.0, accum), wordToReal d), I.+(n, 1), cs')
			  else SOME(accum, n, cs)
		      end
		  | NONE => SOME(accum, n, cs)
		(* end case *))
	  in
	    if (isDecDigit d) then scan(wordToReal d, 1, cs) else NONE
	  end

    local
      val negTbl = #[
	      1.0E~0, 1.0E~1, 1.0E~2, 1.0E~3, 1.0E~4,
	      1.0E~5, 1.0E~6, 1.0E~7, 1.0E~8, 1.0E~9
	    ]
      val posTbl = #[
	      1.0E0, 1.0E1, 1.0E2, 1.0E3, 1.0E4,
	      1.0E5, 1.0E6, 1.0E7, 1.0E8, 1.0E9
	    ]
      fun scale (tbl, step10 : real) = let
	    fun f (r, 0) = r
	      | f (r, exp) = if (I.<(exp, 10))
		  then (R.*(r, InlineT.PolyVector.sub(tbl, exp)))
		  else f (R.*(step10, r), I.-(exp, 10))
	    in
	      f
	    end
    in
    val scaleUp = scale (posTbl, 1.0E10)
    val scaleDown = scale (negTbl, 1.0E~10)
    end

    fun scanReal getc cs = let
	  fun scan10 cs = (case (getc cs)
		 of (SOME(c, cs)) => fscan10 getc (code c, cs)
		  | NONE => NONE
		(* end case *))
	  fun getFrac rest = (case (scan10 rest)
		 of SOME(frac, n, rest) => SOME(scaleDown(frac, n), rest)
		  | NONE => NONE
		(* end case *))
	  fun negate (true, num) = R.~ num
	    | negate (false, num) = num
	  fun scanExp cs = (case (getc cs)
		 of SOME(c, cs) => let
		      val d = code c
		      fun scan (accum, cs) = (case (getc cs)
			     of SOME(c, cs') => let val d = code c
				  in
				    if (isDecDigit d)
				      then scan (I.+(I.*(accum, 10), W.toIntX d), cs')
				      else (accum, cs)
				  end
			      | NONE => (accum, cs)
			    (* end case *))
		      in
			if (isDecDigit d)
			  then SOME (scan (W.toIntX d, cs))
			  else NONE
		      end
		  | NONE => NONE
		(* end case *))
	  fun getExp(num,cs) =
	      case (getc cs)
	        of (SOME(c, cs1)) =>
		    if (code c = eCode)
		    then (case (getc cs1)
			    of SOME(c, cs2) =>
				let val codeC = code c
				    val (isNeg, cs3) =
					if (codeC = minusCode) then (true, cs2)
					else if (codeC = plusCode)
					  then (false, cs2)
					else (false, cs1)  (* no sign *)
				 in case scanExp cs3
				      of SOME(exp, cs4) =>
			                 SOME(if isNeg
					        then scaleDown(num, exp)
					        else scaleUp(num, exp),
				              cs4)
				       | NONE => SOME(num, cs)
				   (* end case *)
				end
			     | NONE => SOME(num, cs)
			 (* end case *))
		    else SOME(num, cs)
		 | NONE => SOME(num, cs)
	     (* end case *)
	  in
	    case (scanPrefix (decPat(false,true)) getc cs)
	     of NONE => NONE
	      | (SOME{neg, next, rest}) =>
		 if (next = ptCode) (* initial point after prefix *)
		 then (case getFrac rest
		         of SOME(frac, rest) => 
		              getExp(negate(neg,frac),rest)
		          | NONE => NONE (* initial point not followed by digit *)
		      (* end case *))
		 else (* ASSERT: next must be a digit *)
		   (* get whole number part *)
		   (case fscan10 getc (next, rest)
		      of SOME(whole, _, rest) =>
			   (case (getc rest)
			     of SOME(#".", rest') =>
				 (* whole part followed by point, get fraction *)
				(case getFrac rest'
				   of SOME(frac,rest'') => (* fraction exists *)
				       getExp(negate(neg,R.+(whole,frac)),rest'')
                                    | NONE =>
				       (* no fraction -- point terminates num *)
				       SOME(negate(neg,whole), rest)
		                 (* end case *))
			      | _ => getExp(negate(neg,whole),rest)
			   (* end case *))
		       | NONE => NONE (* ASSERT: this case can't happen *)
		   (* end case *))
	  end

  end;


