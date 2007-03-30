(* real64.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 *)

structure Real64Imp : REAL = 
  struct
    structure I = InlineT.DfltInt

    structure Math = Math64

    infix 4 == !=
    type real = real
    
    fun *+(a:real,b,c) = a*b+c
    fun *-(a:real,b,c) = a*b-c

    val op == = InlineT.Real64.==
    val op != = InlineT.Real64.!=

    fun unordered(x:real,y) = Bool.not(x>y orelse x <= y)
    fun ?= (x, y) = (x == y) orelse unordered(x, y)

    fun isNormal x = (case Assembly.A.logb x
	   of ~1023 => false	(* 0.0 or subnormal *)
	    | 1024 => false	(* inf or nan *)
	    | _ => true
	  (* end case *))

  (* The next three values are computed laboriously, partly to
   * avoid problems with inaccurate string->float conversions
   * in the compiler itself.
   *)
    val maxFinite = let
	  fun f(x,i) = if i=1023 then x else f(x*2.0, i + 1)
	  val y = f(1.0,0)
	  fun g(z, y, 0) = z
	    | g(z, y, i) = g (z+y, y*0.5, i - 1)
	  in
	    g(0.0,y,53)
	  end

    val minNormalPos = let
	  fun f(x) = let
		val y = x * 0.5
		in
		  if isNormal y then f y else x
		end
	  in
	    f 1.0
	  end

    local
      (* The x86 uses extended precision (80 bits) internally, therefore 
       * it is necessary to write out the result of r * 0.5 to get 
       * 64 bit precision.
       *)
      val mem = InlineT.PolyArray.array(1, minNormalPos)
      val update = InlineT.PolyArray.update
      val subscript = InlineT.PolyArray.chkSub
      fun f () = let
	val r = subscript(mem, 0)
	val y = r * 0.5
      in
	 update(mem, 0, y);
	 if subscript(mem, 0) == 0.0 then r else f ()
      end
    in
      val minPos = f()
    end

    val posInf = maxFinite * maxFinite
    val negInf = ~posInf

    fun isFinite x = negInf < x andalso x < posInf
    fun isNan x = Bool.not(x==x)
    fun floor x = if x < 1073741824.0 andalso x >= ~1073741824.0
	           then Assembly.A.floor x
		  else if isNan x then raise General.Domain
		  else raise General.Overflow

    fun ceil n = ~1 - floor (~1.0 - n)
    fun trunc n = if n < 0.0 then ceil n else floor n
    fun round x =
        (* ties go to the nearest even number *)
	let val fl = floor(x+0.5)
	    val cl = ceil(x-0.5)
	 in if fl=cl then fl
	    else if Word31Imp.andb(Word31Imp.fromInt fl,0w1) = 0w1 then cl else fl
	end

  (* This is the IEEE double-precision maxint *)
    val maxInt = 4503599627370496.0

    local
    (* realround mode x returns x rounded to the nearest integer using the
     * given rounding mode.
     * May be applied to inf's and nan's.
     *)
      fun realround mode x = let
	    val saveMode = IEEEReal.getRoundingMode ()
	    in
	      IEEEReal.setRoundingMode mode;
	      (if x>=0.0 then x+maxInt-maxInt else x-maxInt+maxInt)
		before IEEEReal.setRoundingMode saveMode
	    end
    in
    val realFloor = realround IEEEReal.TO_NEGINF
    val realCeil = realround IEEEReal.TO_POSINF
    val realTrunc = realround IEEEReal.TO_ZERO
    end

    val abs : real -> real = InlineT.Real64.abs
    val fromInt : int -> real = InlineT.real

    fun toInt IEEEReal.TO_NEGINF = floor
      | toInt IEEEReal.TO_POSINF = ceil
      | toInt IEEEReal.TO_ZERO = trunc
      | toInt IEEEReal.TO_NEAREST = round

    fun toLarge x = x
    fun fromLarge _ x = x       

    fun sign x = if (x < 0.0) then ~1 else if (x > 0.0) then 1 
                  else if isNan x then raise Domain else 0
    fun signBit x = (* Bug: negative zero not handled properly *)
                   Assembly.A.scalb(x, ~(Assembly.A.logb x)) < 0.0

    fun sameSign (x, y) = signBit x = signBit y

    fun copySign(x,y) = (* may not work if x is Nan *)
           if sameSign(x,y) then x else ~x

    fun compare(x,y) =
	if x<y then General.LESS
	else if x>y then General.GREATER
        else if x == y then General.EQUAL 
	else raise IEEEReal.Unordered
    
    fun compareReal(x,y) = 
        if x<y then IEEEReal.LESS
	else if x>y then IEEEReal.GREATER
        else if x == y then IEEEReal.EQUAL 
	else IEEEReal.UNORDERED

(** This proably needs to be reorganized **)
    fun class x =  (* does not distinguish between quiet and signalling NaN *)
      if signBit x
       then if x>negInf then if x == 0.0 then IEEEReal.ZERO
	                     else if Assembly.A.logb x = ~1023
			          then IEEEReal.SUBNORMAL
			          else IEEEReal.NORMAL
	                else if x==x then IEEEReal.INF
			             else IEEEReal.NAN IEEEReal.QUIET
       else if x<posInf then if x == 0.0 then IEEEReal.ZERO
	                     else if Assembly.A.logb x = ~1023
			          then IEEEReal.SUBNORMAL
			          else IEEEReal.NORMAL
	                else if x==x then IEEEReal.INF
			             else IEEEReal.NAN IEEEReal.QUIET

    val radix = 2
    val precision = 52

    val radix_to_the_precision = 18014398509481984.0

    val two_to_the_neg_1000 =
      let fun f(i,x) = if i=0 then x else f(i - 1, x*0.5)
       in f(1000, 1.0)
      end

 (* AARGH!  Our version of logb gives a value that's one less than the
        rest of the world's logb functions.
        We should fix this systematically some time. *)

    fun toManExp x = 
      case Assembly.A.logb x + 1
	of ~1023 => if x==0.0 then {man=x,exp=0}
		    else let val {man=m,exp=e} = toManExp(x*1048576.0)
		              in { man = m, exp = e - 20 }
			 end
         | 1024 => {man=x,exp=0}
         | i => {man=Assembly.A.scalb(x, ~i),exp=i}

    fun fromManExp {man=m,exp=e:int} =
      if (m >= 0.5 andalso m <= 1.0  orelse m <= ~0.5 andalso m >= ~1.0)
	then if e > 1020
	  then if e > 1050 then if m>0.0 then posInf else negInf
	       else let fun f(i,x) = if i=0 then x else f(i-1,x+x)
		       in f(e-1020,  Assembly.A.scalb(m,1020))
		      end
	  else if e < ~1020
	       then if e < ~1200 then 0.0
		 else let fun f(i,x) = if i=0 then x else f(i-1, x*0.5)
		       in f(1020-e, Assembly.A.scalb(m, ~1020))
		      end
	       else Assembly.A.scalb(m,e)  (* This is the common case! *)
      else let val {man=m',exp=e'} = toManExp m
            in fromManExp { man = m', exp = e'+ e }
           end

    fun fromLargeInt(x : IntInf.int) = let
	val CoreIntInf.BI { negative, digits } = CoreIntInf.concrete x
	val w2r = fromInt o InlineT.Word31.copyt_int31
	val base = w2r CoreIntInf.base
	fun calc [] = 0.0
	  | calc (d :: ds) = w2r d + base * calc ds
	val m = calc digits
    in
	if negative then ~m else m
    end

  (* whole and split could be implemented more efficiently if we had
   * control over the rounding mode; but for now we don't.
   *)
    fun whole x = if x>0.0 
		    then if x > 0.5
		      then x-0.5+maxInt-maxInt
		      else whole(x+1.0)-1.0
	          else if x<0.0
                    then if x < ~0.5
		      then x+0.5-maxInt+maxInt
		      else whole(x-1.0)+1.0
	          else x

    fun split x = let val w = whole x 
                      val f = x-w
		   in if abs(f)==1.0
		     then {whole=w+f,frac=0.0}
		     else {whole=w, frac=f} 
		  end

    fun realMod x = let
	  val f = x - whole x
	  in
	    if abs f == 1.0 then 0.0 else f
	  end

    fun rem(x,y) = y * #frac(split(x/y))

    fun checkFloat x = if x>negInf andalso x<posInf then x
                       else if isNan x then raise General.Div
			 else raise General.Overflow

    val rbase = 1073741824.0	(* should be taken from CoreIntInf.base *)

    fun toLargeInt mode x =
	if isNan x then raise Domain
	else if x == posInf orelse x == negInf then raise Overflow
	else let val (negative, x) =
		     if x < 0.0 then (true, ~x) else (false, x)
		 fun feven x = #frac (split (x / 2.0)) == 0.0
	     in
		 (* if the magnitute is less or equal than 1.0, then
		  * we just have to figure out whether to return ~1, 0, or 1
		  *)
		 if x <= 1.0 then
		     case mode of
			 IEEEReal.TO_ZERO => 0
		       | IEEEReal.TO_POSINF =>
			   if negative then 0 else 1
		       | IEEEReal.TO_NEGINF =>
			   if negative then ~1 else 0
		       | IEEEReal.TO_NEAREST =>
			   if x < 0.5 then 0
			   else if x > 0.5 then
			       if negative then ~1 else 1
			   else 0	(* 0 is even *)
		 else
		     (* Otherwise we start with an integral value,
		      * suitably adjusted according to fractional part
		      * and rounding mode: *)
		     let val { whole, frac } = split x
			 val start =
			     case mode of
				 IEEEReal.TO_NEGINF =>
				   if frac > 0.0 andalso negative then
				       whole + 1.0
				   else whole
			       | IEEEReal.TO_POSINF =>
				   if frac > 0.0 andalso not negative then
				       whole + 1.0
				   else whole
			       | IEEEReal.TO_ZERO => whole
			       | IEEEReal.TO_NEAREST =>
				   if frac > 0.5 then whole + 1.0
				   else if frac < 0.5 then whole
				   else if feven whole then whole
				   else whole + 1.0

			 (* Now, for efficiency, we construct the
			  * minimal whole number with
			  * all the significant bits.  First
			  * we get mantissa and exponent: *)
			 val { man, exp } = toManExp x
			 (* Then we adjust both to make sure the mantissa
			  * is whole: *)
			 fun adjust (man, exp) =
			     if exp = 0 orelse #frac (split man) == 0.0 then
				 (man, exp)
			     else adjust (2.0 * man, exp - 1)
			 val (man, exp) = adjust (man, exp)

			 (* Now we can construct our bignum digits by
			  * repeated div/mod using the bignum base: *)
			 fun loop x =
			     if x == 0.0 then []
			     else
				 let val { whole, frac } = split (x / rbase)
				     val dig = InlineT.Word31.copyf_int31
						   (Assembly.A.floor
							(frac * rbase))
				 in
				     dig :: loop whole
				 end
			 (* Now we make a bignum out of those digits: *)
			 val iman =
			     CoreIntInf.abstract
				 (CoreIntInf.BI { negative = negative,
						  digits = loop start })
		     in
			 (* Finally, we have to put the exponent back
			  * into the picture: *)
			 IntInfImp.<< (iman, InlineT.Word31.copyf_int31 exp)
		     end
	     end
  
    fun nextAfter _ = raise Fail "Real.nextAfter unimplemented"

    val min : real * real -> real = InlineT.Real64.min
    val max : real * real -> real = InlineT.Real64.max
(*
    fun min(x,y) = if x<y orelse isNan y then x else y
    fun max(x,y) = if x>y orelse isNan y then x else y
*)

    fun toDecimal _ = raise Fail "Real.toDecimal unimplemented"
    fun fromDecimal _ = raise Fail "Real.fromDecimal unimplemented"

    val fmt = RealFormat.fmtReal
    val toString = fmt (StringCvt.GEN NONE)
    val scan = NumScan.scanReal
    val fromString = StringCvt.scanString scan

    val ~ = InlineT.Real64.~
    val op +  = InlineT.Real64.+
    val op -  = InlineT.Real64.-
    val op *  = InlineT.Real64.*
    val op /  = InlineT.Real64./

    val op >  = InlineT.Real64.>
    val op <  = InlineT.Real64.<
    val op >= = InlineT.Real64.>=
    val op <= = InlineT.Real64.<=

  end (* Real64 *)
