(* int-inf.sml
 *
 * COPYRIGHT (c) 1995 by AT&T Bell Laboratories.
 *     See COPYRIGHT file for details.
 *
 * COPYRIGHT (c) 2003 by The SML/NJ Fellowship.
 *
 * Author of the current code: Matthias Blume (blume@tti-c.org)
 *
 * The implementation in this file, together with its counterpart
 * in system/smlnj/init/core-intinf.sml, is derived from an earlier
 * implementation of IntInf in the SML/NJ utility library.  That
 * implementation, in turn, was derived from Andrzej Filinski's
 * bignum package.
 *
 * The idea is that this package conforms to the specification of
 * IntInf as described in the SML Basis library reference.
 *
 * The type IntInf.int itself is abstract.  A concrete version (together
 * with conversions between abstract and concrete) is provided
 * by structure CoreIntInf.  (The type is a built-in type because
 * the compiler must have some intrinsic knowledge of it in order to
 * be able to implement
 *   - IntInf.int literals
 *   - conversion shortcuts (Int32.fromLarge o Int.toLarge, etc.)
 *   - overloading on literals
 *   - pattern matching on literals
 *
 * Structure CoreIntInf implements all the "essential" pieces which
 * are required for the pervasive environment and for supporting the
 * compiler (literals, conversions).
 *
 * The present structure implements the rest and provides the complete
 * interface as mandated by the Basis spec.
 *
 * The current implementation is not as efficient as it could and should
 * be.
 *)
structure IntInfImp :> INT_INF = struct

    type int = IntInf.int

    val precision = NONE
    val minInt = NONE
    val maxInt = NONE

    (* The following assumes LargeInt = Int32.
     * If IntInf is provided, it will be LargeInt and toLarge and fromLarge
     * will be the identity function.
     *)
    val toInt = InlineT.IntInf.toInt
    val fromInt = InlineT.IntInf.fromInt
    val toLarge = InlineT.IntInf.toLarge
    val fromLarge = InlineT.IntInf.fromLarge

    datatype rep = datatype CoreIntInf.rep
    val concrete = CoreIntInf.concrete
    val abstract = CoreIntInf.abstract
    val baseBits = Word31Imp.toIntX CoreIntInf.baseBits

    fun binary (f, genSign) (x, y) = let
	val BI{negative=sx,digits=xs} = concrete x
	val BI{negative=sy,digits=ys} = concrete y

	val sign = genSign (sx, sy)

        (* convert to two's complement;
         * Compute (- x - borrow)
         *)
        fun twos (false, x, borrow) = (x, 0w0)
          | twos (true, 0w0, 0w0) = (0w0, 0w0) (* no borrow *)
          | twos (true, x, borrow) =
	      (CoreIntInf.base - x - borrow, 0w1) (* borrow *)

        (* convert to ones's complement *)
        val ones = twos 

        fun loop ([], [], _, _, _) = []
          | loop ([], y :: ys, bx, by, bz)  = 
              loop1 (0w0, [], y, ys, bx, by, bz)
          | loop (x :: xs, [], bx, by, bz) = 
              loop1 (x, xs, 0w0, [], bx, by, bz)
          | loop (x :: xs, y::ys, bx, by, bz) = 
              loop1 (x, xs, y, ys, bx, by, bz)

	and loop1 (x, xs, y, ys, bx, by, bz) = 
            let (* convert from ones complement *)
                val (x, bx) = twos (sx, x, bx)
                val (y, by) = twos (sy, y, by)
                val z  = f (x,y)
                (* convert back to ones complement *)
                val (z, bz) = ones (sign, z, bz)
                val zs = loop (xs, ys, bx, by, bz)
            in
		case (z, zs) of  (* strip leading zero *)
                    (0w0, []) => []
                  | (z, zs) => z :: zs
            end
    in
	case loop (xs, ys, 0w0, 0w0, 0w0) of
	    [] => abstract (BI { digits = [], negative = false })
          | digits => abstract (BI { negative = sign, digits = digits })
    end

    fun shiftAmount w =
	{ bytes = Word31Imp.div (w, CoreIntInf.baseBits),
	  bits = Word31Imp.mod (w, CoreIntInf.baseBits) }

    infix || && << >>
    val op << = Word31Imp.<<
    val op >> = Word31Imp.>>
    val op && = Word31Imp.andb
    val op || = Word31Imp.orb

    (* formatting for bases 2, 8, 16 by slicing off the right number of
     * bits... *)
    fun bitfmt (bits, maxdig, digvec) i = let
	fun dig d = StringImp.sub (digvec, Word31Imp.toIntX d)
	fun loop (chars, [], 0w0, _) = StringImp.implode chars
	  | loop (chars, xs, c, cb) =
	    if cb >= bits then
		loop (dig (c && maxdig) :: chars,
		      xs, c >> bits, cb - bits)
	    else let val (x, xs') =
			 case xs of [] => (0w0, [])
				  | x :: xs' => (x, xs')
		     val a = ((x << cb) || c) && maxdig
		 in
		     loop (dig a :: chars, xs',
			   x >> (bits - cb),
			   CoreIntInf.baseBits - bits + cb)
		 end
    in
	case concrete i of
	    BI { digits = [], ... } => "0"
	  | BI { negative, digits } =>
	    loop (if negative then [#"~"] else [], digits, 0w0, 0w0)
    end			    

    val (decBase, decDigs) = let
	fun try (b, d) =
	    if b <= CoreIntInf.base then (b, d)
	    else try (Word31Imp.div (b, 0w10), d - 1)
    in
	try (0w1000000000, 9)
    end

    (* decimal formatting by repeatedly dividing by the largest
     * possible power of 10: *)
    fun decfmt i = let
	val toString = Word31Imp.fmt StringCvt.DEC
	fun decDig d = StringCvt.padLeft #"0" decDigs (toString d)

	fun loop (l, []) = l
	  | loop (l, [x]) = toString x :: l
	  | loop (l, xs) = let
		val (q, r) = CoreIntInf.natdivmodd (xs, decBase)
	    in
		loop (decDig r :: l, q)
	    end
    in
	case concrete i of
	    BI { digits = [], ... } => "0"
	  | BI { digits, negative } =>
	      concat (if negative then "~" :: loop ([], digits)
		      else loop ([], digits))
    end

    fun fmt StringCvt.OCT = bitfmt (0w3, 0wx7, "01234567")
      | fmt StringCvt.HEX = bitfmt (0w4, 0wxf, "0123456789abcdef")
      | fmt StringCvt.BIN = bitfmt (0w1, 0wx1, "01")
      | fmt StringCvt.DEC = decfmt

    fun sign i =
	case concrete i of
	    BI { digits = [], ... } => 0
	  | BI { negative, ... } => if negative then ~1 else 1

    fun sameSign (i,j) = sign i = sign j

    fun notb x = ~(x + abstract (BI { negative = false, digits = [0w1] }))

    fun log2 i =
	case concrete i of
	    BI { negative = true, ... } => raise Domain
	  | BI { digits, ... } => let
		fun wloop (0w0, _) = raise Domain (* should never happen *)
	          | wloop (0w1, lg) = lg
		  | wloop (w, lg) = wloop (Word31Imp.>> (w, 0w1), lg + 1)
		fun loop ([], lg) = raise Domain
		  | loop ([x], lg) = wloop (x, lg)
		  | loop (x :: xs, lg) = loop (xs, lg + baseBits)
	    in
		loop (digits, 0)
	    end

    val orb = binary (Word31Imp.orb, fn (x, y) => x orelse y)
    val andb = binary (Word31Imp.andb, fn (x, y) => x andalso y)
    val xorb = binary (Word31Imp.xorb, fn (x, y) => x <> y)

    (* left shift; just shift the digits, no special treatment for
     * signed versus unsigned. *)
    fun lshift (i, w) =
	case concrete i of
	    BI { digits = [], negative } => i (* i = 0 *)
	  | BI { digits, negative } =>  let
		val { bytes, bits } = shiftAmount w
		val bits' = CoreIntInf.baseBits - bits
		fun pad (0w0, xs) = xs
		  | pad (n, xs) = pad (n-0w1, 0w0 :: xs)
		fun shift ([], 0w0) = []
		  | shift ([], carry) = [carry]
		  | shift (x :: xs, carry) = let
			val maxVal = CoreIntInf.maxDigit
			val digit = ((x << bits) || carry) && maxVal
			val carry' = x >> bits'
		    in
			digit :: shift (xs, carry')
		    end
	    in
		abstract
		    (BI { negative = negative,
			  digits =
			  if bits = 0w0 then
			      pad (bytes, digits)
			  else
			      pad (bytes, shift (digits, 0w0)) })
	    end

    (* Right shift. *)
    fun rshift (i, w) =
	case concrete i of
	    BI { digits = [], negative } => i (* i = 0 *)
	  | BI { digits, negative } => let
		val { bytes, bits } = shiftAmount w
		val bits' = CoreIntInf.baseBits - bits
		fun drop (0w0, i) = i 
		  | drop (n, []) = []
		  | drop (n, x :: xs) = drop (n-0w1, xs)
		fun shift [] = ([], 0w0)
		  | shift (x :: xs) =
		    let val (zs, borrow) = shift xs
			val z = borrow || (x >> bits)
			val borrow' = (x << bits') && CoreIntInf.maxDigit
		    in
			(* strip leading 0 *)
			case (z, zs) of
			    (0w0, []) => ([], borrow')
			  | _ => (z :: zs, borrow')
		    end
			
		val digits =
		    if bits = 0w0 then drop (bytes, digits)
		    else #1 (shift (drop (bytes, digits)))
	    in
		abstract (case digits of
			      [] => BI { negative = false, digits = [] }
			    | _ => BI { negative = negative,
					digits = digits })
	    end

    fun startscan (doit, hex) getchar s = let
	fun hexprefix (neg, s) =
	    case getchar s of
		SOME ((#"x" | #"X"), s') => doit (neg, s')
	      | _ => doit (neg, s)
	fun prefix (neg, s) =
	    if hex then hexprefix (neg, s)
	    else doit (neg, s)
	fun sign s =
	    case getchar s of
		NONE => NONE
	      | SOME ((#"-" | #"~"), s') => prefix (true, s')
	      | SOME (#"+", s') => prefix (false, s')
	      | _ => prefix (false, s)
    in
	sign (StringCvt.skipWS getchar s)
    end

    fun bitscan (bits, digVal, hex) getchar s = let

	fun dcons (0w0, []) = []
	  | dcons (x, xs) = x :: xs

	fun checkFirstDigit (neg, s) = let
	    val pos0 = CoreIntInf.baseBits - bits
	    val maxVal = CoreIntInf.maxDigit

	    fun digloop (d, pos, nat, s) = let
		fun done () = let
		    val i =
			case dcons (d, nat) of
			    [] => BI { negative = false, digits = [] }
			  | nat => BI { negative = neg, digits = nat }
		    val i = abstract i
		in
		    SOME (if pos = 0w0 then i else (rshift (i, pos)), s)
		end
	    in
		case getchar s of
		    NONE => done ()
		  | SOME (c, s') =>
		    (case digVal c of
			 NONE => done ()
		       | SOME v =>
			 if pos < bits then
			     if pos = 0w0 then
				 digloop (v << pos0, pos0, dcons (d, nat), s')
			     else
				 digloop ((v << (pos0 + pos)) && maxVal,
					  pos0 + pos,
					  dcons (d || (v >> (bits - pos)), nat),
					  s')
			 else
			     digloop (d || (v << (pos - bits)), pos - bits,
				      nat, s'))
	    end
	in
	    case getchar s of
		NONE => NONE
	      | SOME (c, s') =>
		  (case digVal c of
		       SOME v => digloop (v << pos0, pos0, [], s')
		     | NONE => NONE)
	end
				   
    in
	startscan (checkFirstDigit, hex) getchar s
    end

    fun decscan getchar s = let
	fun digVal #"0" = SOME 0w0
	  | digVal #"1" = SOME 0w1
	  | digVal #"2" = SOME 0w2
	  | digVal #"3" = SOME 0w3
	  | digVal #"4" = SOME 0w4
	  | digVal #"5" = SOME 0w5
	  | digVal #"6" = SOME 0w6
	  | digVal #"7" = SOME 0w7
	  | digVal #"8" = SOME 0w8
	  | digVal #"9" = SOME 0w9
	  | digVal _ = NONE

	fun digloop (negative, nat, fact, v, s) = let
	    fun done () = let
		val i = case CoreIntInf.natmadd (fact, nat, v) of
			    [] => abstract (BI { negative = false,
						 digits = [] })
			  | digits => abstract (BI { negative = negative,
						     digits = digits })
	    in
		SOME (i, s)
	    end
	in
	    case getchar s of
		SOME (c, s') =>
		(case digVal c of
		     SOME v' =>
		     if fact = decBase then
			 digloop (negative,
				  CoreIntInf.natmadd (fact, nat, v),
				  0w10, v', s')
		     else
			 digloop (negative,
				  nat, fact * 0w10, v * 0w10 + v', s')
		   | NONE => done ())
	      | NONE => done ()
	end

	fun checkFirstDigit (negative, s) =
	    case getchar s of
		NONE => NONE
	      | SOME (c, s') =>
		  (case digVal c of
		       SOME v => digloop (negative, [], 0w10, v, s')
		     | NONE => NONE)
    in
	startscan (checkFirstDigit, false) getchar s
    end

    fun binDigVal #"0" = SOME 0w0
      | binDigVal #"1" = SOME 0w1
      | binDigVal _ = NONE

    fun octDigVal #"0" = SOME 0w0
      | octDigVal #"1" = SOME 0w1
      | octDigVal #"2" = SOME 0w2
      | octDigVal #"3" = SOME 0w3
      | octDigVal #"4" = SOME 0w4
      | octDigVal #"5" = SOME 0w5
      | octDigVal #"6" = SOME 0w6
      | octDigVal #"7" = SOME 0w7
      | octDigVal _ = NONE

    fun hexDigVal #"0" = SOME 0wx0
      | hexDigVal #"1" = SOME 0wx1
      | hexDigVal #"2" = SOME 0wx2
      | hexDigVal #"3" = SOME 0wx3
      | hexDigVal #"4" = SOME 0wx4
      | hexDigVal #"5" = SOME 0wx5
      | hexDigVal #"6" = SOME 0wx6
      | hexDigVal #"7" = SOME 0wx7
      | hexDigVal #"8" = SOME 0wx8
      | hexDigVal #"9" = SOME 0wx9
      | hexDigVal (#"a" | #"A") = SOME 0wxa
      | hexDigVal (#"b" | #"B") = SOME 0wxb
      | hexDigVal (#"c" | #"C") = SOME 0wxc
      | hexDigVal (#"d" | #"D") = SOME 0wxd
      | hexDigVal (#"e" | #"E") = SOME 0wxe
      | hexDigVal (#"f" | #"F") = SOME 0wxf
      | hexDigVal _ = NONE

    fun scan StringCvt.DEC = decscan
      | scan StringCvt.HEX = bitscan (0w4, hexDigVal, true)
      | scan StringCvt.OCT = bitscan (0w3, octDigVal, false)
      | scan StringCvt.BIN = bitscan (0w1, binDigVal, false)

    val ~ = CoreIntInf.~
    val op + = CoreIntInf.+
    val op * = CoreIntInf.*
    val op div = CoreIntInf.div
    val op mod = CoreIntInf.mod
    val op - = CoreIntInf.-
    val op < = CoreIntInf.<
    val op <= = CoreIntInf.<=
    val op > = CoreIntInf.>
    val op >= = CoreIntInf.>=

    val divMod = CoreIntInf.divMod
    val quotRem = CoreIntInf.quotRem
    val quot = CoreIntInf.quot
    val rem = CoreIntInf.rem
    val compare = CoreIntInf.compare
    val abs = CoreIntInf.abs
    val pow = CoreIntInf.pow

    fun max arg = case compare arg of GREATER => #1 arg | _ => #2 arg
    fun min arg = case compare arg of LESS => #1 arg | _ => #2 arg

    val toString = fmt StringCvt.DEC
    fun fromString s = StringCvt.scanString (scan StringCvt.DEC) s

    val op << = lshift
    val ~>> = rshift
end (* structure IntInf *)
