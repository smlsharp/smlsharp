(**
 * Real, Real64, LargeReal, Math
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

infix 7 * / div mod
infix 6 + - ^
infixr 5 ::
infix 4 = <> > >= < <=
val op ^ = String.^
val ! = SMLSharp_Builtin.General.!
structure Int32 = SMLSharp_Builtin.Int32
structure Real64 = SMLSharp_Builtin.Real64
structure Pointer = SMLSharp_Builtin.Pointer
structure Array = SMLSharp_Builtin.Array
structure String = SMLSharp_Builtin.String
structure Word8 = SMLSharp_Builtin.Word8
structure Char = SMLSharp_Builtin.Char

structure Real64 =
struct

  type real = real

  (* IEEE 754 double precision floating point number *)
  val radix = 2
  val precision = 53
  (* 7fe f ff ff ff ff ff ff *)
  val maxFinite = 1.7976931348623157e308 : real
  (* 000 0 00 00 00 00 00 01 *)
  val minPos = 4.9406564584124654e~324 : real
  (* 001 0 00 00 00 00 00 00 *)
  val minNormalPos = 2.2250738585072013e~308 : real
  (* 7ff 0 00 00 00 00 00 00 *)
  val posInf = Real64.div (1.0, 0.0)
  (* fff 0 00 00 00 00 00 00 *)
  val negInf = Real64.div (~1.0, 0.0)

  structure Math =
  struct
    type real = real

    (* 400 9 21 fb 54 44 2d 18 *)
    val pi = 3.141592653589793 : real
    (* 400 5 bf 0a 8b 14 57 69 *)
    val e = 2.718281828459045 : real

    val sqrt =
        _import "sqrt"
        : __attribute__((pure,fast)) real -> real
    val sin =
        _import "sin"
        : __attribute__((pure,fast)) real -> real
    val cos =
        _import "cos"
        : __attribute__((pure,fast)) real -> real
    val tan =
        _import "tan"
        : __attribute__((pure,fast)) real -> real
    val asin =
        _import "asin"
        : __attribute__((pure,fast)) real -> real
    val acos =
        _import "acos"
        : __attribute__((pure,fast)) real -> real
    val atan =
        _import "atan"
        : __attribute__((pure,fast)) real -> real
    val atan2 =
        _import "atan2"
        : __attribute__((pure,fast)) (real, real) -> real
    val exp =
        _import "exp"
        : __attribute__((pure,fast)) real -> real
    val pow' =
        _import "pow"
        : __attribute__((pure,fast)) (real, real) -> real
    val nan =
        Real64.mul (0.0, posInf)
    fun pow (x, y) =
        if SMLSharp_RealClass.isInf (SMLSharp_RealClass.classReal y)
        then (
          if Real64.equal (x, 1.0) orelse Real64.equal (x, ~1.0)
          then nan
          else pow' (x, y))
        else pow' (x, y)
    val ln =
        _import "log"
        : __attribute__((pure,fast)) real -> real
    val log10 =
        _import "log10"
        : __attribute__((pure,fast)) real -> real
    val sinh =
        _import "sinh"
        : __attribute__((pure,fast)) real -> real
    val cosh =
        _import "cosh"
        : __attribute__((pure,fast)) real -> real
    val tanh =
        _import "tanh"
        : __attribute__((pure,fast)) real -> real
  end

  val op + = Real64.add
  val op - = Real64.sub
  val op * = Real64.mul
  val op / = Real64.div
  (* NOTE: Real64.rem is not same as remainder(3) defined in C99. *)
  val rem = Real64.rem
  val ~ = Real64.neg
  val abs = Real64.abs
  val op < = Real64.lt
  val op <= = Real64.lteq
  val op > = Real64.gt
  val op >= = Real64.gteq
  val == = Real64.equal
  val != = Real64.notEqual
  val ?= = Real64.ueq
  val isNan = Real64.isNan
  val trunc = Real64.trunc
  val fromInt = Real64.fromInt32

  fun *+ (r1, r2, r3) = r1 * r2 + r3
  fun *- (r1, r2, r3) = r1 * r2 - r3

  fun min (x, y) =
      if isNan x then y
      else if isNan y then x
      else if Real64.lteq (x, y) then x else y
  fun max (x, y) =
      if isNan x then y
      else if isNan y then x
      else if Real64.lteq (x, y) then y else x
  fun sign x =
      if isNan x then raise Domain
      else SMLSharp_RealClass.sign (SMLSharp_RealClass.classReal x)
  fun signBit x = SMLSharp_RealClass.signBit (SMLSharp_RealClass.classReal x)
  fun sameSign (x, y) = signBit x = signBit y
  fun isFinite x = SMLSharp_RealClass.isFinite (SMLSharp_RealClass.classReal x)
  fun unordered (x, y) = isNan x orelse isNan y
  fun isNormal x = SMLSharp_RealClass.isNormal (SMLSharp_RealClass.classReal x)
  fun class x = SMLSharp_RealClass.class (SMLSharp_RealClass.classReal x)

  val copySign =
      _import "copysign"
      : __attribute__((pure,fast)) (real, real) -> real

  fun compareReal (x, y) =
      if Real64.lt (x, y) then IEEEReal.LESS
      else if Real64.gt (x, y) then IEEEReal.GREATER
      else if Real64.equal (x, y) then IEEEReal.EQUAL
      else IEEEReal.UNORDERED

  fun compare (x, y) =
      case compareReal (x, y) of
        IEEEReal.UNORDERED => raise IEEEReal.Unordered
      | IEEEReal.LESS => General.LESS
      | IEEEReal.EQUAL => General.EQUAL
      | IEEEReal.GREATER => General.GREATER

  val frexp =
      _import "frexp"
      : __attribute__((pure,fast)) (real, int ref) -> real
  val ldexp =
      _import "ldexp"
      : __attribute__((pure,fast)) (real, int) -> real
  val modf =
      _import "modf"
      : __attribute__((pure,fast)) (real, real ref) -> real

  fun toManExp x =
      let val exp = ref 0
          val man = frexp (x, exp)
      in {man = man, exp = !exp}
      end

  fun fromManExp {man, exp} =
      ldexp (man, exp)

  fun split x =
      let val intg = ref 0.0
          val frac = modf (x, intg)
      in {whole = !intg, frac = frac}
      end

  fun realMod x = #frac (split x)

(* bug 299_RealNextAfter
  val nextAfter =
      _import "nextafter"
      : __attribute__((pure,fast)) (real, real) -> real
*)
  val nextafter =
      _import "nextafter"
      : __attribute__((pure,fast)) (real, real) -> real

  fun nextAfter (r, t) =
      case (class r, class t) of
	(IEEEReal.INF, IEEEReal.NAN) => nextafter(r, t)
      | (IEEEReal.INF, _) => r
      | _ => nextafter (r, t)

  fun checkFloat x =
      case class x of
        IEEEReal.INF => raise Overflow
      | IEEEReal.NAN => raise Div (* Domain? This is a bug of Basis spec? *)
      | _ => x

  val realFloor =
      _import "floor"
      : __attribute__((pure,fast)) real -> real
  val realCeil =
      _import "ceil"
      : __attribute__((pure,fast)) real -> real
  val realTrunc =
      _import "trunc"
      : __attribute__((pure,fast)) real -> real

  fun floorOrCeil r =
      if signBit r then realFloor r else realCeil r

  fun realRound r =
      let
        val {whole, frac} = split r
        val frac = abs frac
      in
        if frac < 0.5
        then whole
        else if frac > 0.5
        then floorOrCeil r
        else if == (rem (whole, 2.0), 0.0)
        then whole
        else floorOrCeil r
      end

  fun floor x = Real64.trunc (realFloor x)
  fun ceil x = Real64.trunc (realCeil x)
  fun round x = Real64.trunc (realRound x)

  fun toInt mode x =
      if isNan x then raise Domain else
      case mode of
        IEEEReal.TO_NEGINF => floor x
      | IEEEReal.TO_POSINF => ceil x
      | IEEEReal.TO_ZERO => trunc x
      | IEEEReal.TO_NEAREST => round x

  val IntInf_fromReal =
      _import "prim_IntInf_fromReal"
      : __attribute__((unsafe,pure,fast,gc)) real -> intInf

  fun toLargeInt mode x =
      case SMLSharp_RealClass.class (SMLSharp_RealClass.classReal x) of
        IEEEReal.NAN => raise Domain
      | IEEEReal.INF => raise Overflow
      | _ => IntInf_fromReal
               (case mode of
                  IEEEReal.TO_NEGINF => realFloor x
                | IEEEReal.TO_POSINF => realCeil x
                | IEEEReal.TO_ZERO => x
                | IEEEReal.TO_NEAREST => realRound x)

  val fromLargeInt =
      _import "prim_IntInf_toReal"
      : __attribute__((pure,fast))  largeInt -> real

  fun toLarge x = x : real
  fun fromLarge (mode:IEEEReal.rounding_mode) x = x : real

  local
    val sml_dtoa =
        _import "sml_dtoa"
        : __attribute__((fast))
          (real, int, int, int ref, int ref, char ptr ptr) -> char ptr
    val sml_freedtoa =
        _import "sml_freedtoa"
        : __attribute__((fast)) char ptr -> ()
    val str_new =
        _import "sml_str_new"
        : __attribute__((unsafe,fast,gc)) char ptr -> string

    fun dtoa (mode, ndigit, value) =
        let
          val decpt = ref 0
          val sign = ref 0
          val s = sml_dtoa (value, mode, ndigit, decpt, sign,
                            Pointer.null ())
          val digits = str_new s
          val _ = sml_freedtoa s
        in
          {decpt = !decpt,
           digits = digits,
           sign = if !sign = 0 then false else true}
        end
  in
  fun ecvt (value, ndigit) = dtoa (2, ndigit, value)
  fun fcvt (value, ndigit) = dtoa (3, ndigit, value)
  fun exactCvt value = dtoa (0, 0, value)
  end (* local *)

  local
    val sml_strtod =
        _import "sml_strtod"
        : __attribute__((pure,fast))
          (string, char ptr ptr) -> real
  in
  fun strtod str = sml_strtod (str, Pointer.null ())
  end (* local *)

  local
    val op + = SMLSharp_Builtin.Int32.add_unsafe
    val op - = SMLSharp_Builtin.Int32.sub_unsafe
    val op > = SMLSharp_Builtin.Int32.gt
    val op >= = SMLSharp_Builtin.Int32.gteq
    val op < = SMLSharp_Builtin.Int32.lt
    val op <= = SMLSharp_Builtin.Int32.lteq
  in

  fun storeSign (buf, sign) =
      if sign
      then Array.update_unsafe (buf, 0, #"~")
      else ()

  fun fillZero (buf, index, limit) =
      let
        fun loop i =
            if i >= limit then ()
            else (Array.update_unsafe (buf, i, #"0");
                  loop (i+1))
      in
        loop index
      end

  (* prec is given from the users and therefore the string representation
   * of a real may exceed the size limit of strings. *)
  fun insertSignAndDot (sign, decpt, digits, prec) =
      let
        val plen = if sign then 1 else 0
        val slen = String.size digits
      in
        if decpt <= 0 then
          let
            local
              val op + = Int32.add
              val op - = Int32.sub
            in
            val pzeroes = 0 - decpt handle Overflow => raise Size
            val frac = pzeroes + slen handle Overflow => raise Size
            val tzeroes =
                (if frac < prec then prec - frac else 0)
                handle Overflow => raise Size
            val frac = frac + tzeroes handle Overflow => raise Size
            val frac =
                (if 0 < frac then frac + 1 else 0)
                handle Overflow => raise Size
            val buflen = plen + 1 + frac handle Overflow => raise Size
            val buf = String.alloc buflen
            end
          in
            storeSign (String.castToArray buf, sign);
            Array.update_unsafe (String.castToArray buf, plen, #"0");
            if frac > 0
            then (Array.update_unsafe (String.castToArray buf,
                                       plen + 1, #".");
                  fillZero (String.castToArray buf, plen + 2,
                            plen + 2 + pzeroes);
                  Array.copy_unsafe
                    (String.castToArray digits, 0,
                     String.castToArray buf, plen + 2 + pzeroes, slen);
                  if tzeroes > 0
                  then fillZero (String.castToArray buf,
                                 plen + 2 + pzeroes + slen, buflen)
                  else ())
            else ();
            buf
          end
        else if slen <= decpt then
          let
            local
              val op + = Int32.add
              val op - = Int32.sub
            in
            val zeroes = decpt - slen handle Overflow => raise Size
            val frac = (if 0 < prec then prec + 1 else 0)
                       handle Overflow => raise Size
            val buflen = plen + slen + zeroes + frac
                         handle Overflow => raise Size
            val buf = String.alloc buflen
            end
          in
            storeSign (String.castToArray buf, sign);
            Array.copy_unsafe (String.castToArray digits, 0,
                               String.castToArray buf, plen, slen);
            fillZero (String.castToArray buf,
                      plen + slen, plen + slen + zeroes);
            if frac > 0
            then let val i = plen + slen + zeroes
                 in Array.update_unsafe (String.castToArray buf, i, #".");
                    fillZero (String.castToArray buf, i + 1, buflen)
                 end
            else ();
            buf
          end
        else
          let
            local
              val op + = Int32.add
              val op - = Int32.sub
            in
            val frac = slen - decpt handle Overflow => raise Size
            val zeroes = (if frac < prec then prec - frac else 0)
                         handle Overflow => raise Size
            val buflen = plen + slen + 1 + zeroes handle Overflow => raise Size
            val buf = String.alloc buflen
            end
          in
            storeSign (String.castToArray buf, sign);
            Array.copy_unsafe (String.castToArray digits, 0,
                               String.castToArray buf, plen, decpt);
            Array.update_unsafe (String.castToArray buf,
                                 plen + decpt, #".");
            Array.copy_unsafe
              (String.castToArray digits, decpt,
               String.castToArray buf, plen + decpt + 1, slen - decpt);
            if zeroes > 0
            then fillZero (String.castToArray buf, plen + slen + 1, buflen)
            else ();
            buf
          end
      end

  fun intToChars sign n pos =
      let
        val op - = Int32.sub_unsafe
        fun loop (n, z, len) =
            if n = 0 then (z, len)
            else let val q = Int32.quot_unsafe (n, 10)
                     val r = Int32.rem_unsafe (n, 10)
                 in loop (q, Word8.castToChar
                               (Word8.sub (0wx30, Word8.fromInt32 r)) :: z,
                          Int32.add (len, 1))
                 end
      in
        if n = 0 then ([#"0"], Int32.add (pos, 1))
        else if 0 < n then loop (0 - n, nil, pos)
        else case loop (n, nil, Int32.add (pos, 1)) of (l, n) => (sign::l, n)
      end

  fun copyChars (buf, i, nil) = ()
    | copyChars (buf, i, h::t) =
      (Array.update_unsafe (String.castToArray buf, i, h);
       copyChars (buf, i + 1, t))

  fun appendExponent (str, sign, exp) =
      let
        val slen = String.size str
        val (exp, allocSize) =
            intToChars sign exp (Int32.add (slen, 1))
            handle Overflow => raise Size
        val buf = String.alloc allocSize
      in
        Array.copy_unsafe (String.castToArray str, 0,
                           String.castToArray buf, 0, slen);
        Array.update_unsafe (String.castToArray buf, slen, #"E");
        copyChars (buf, slen + 1, exp);
        buf
      end

  fun fmtFIX prec value =
      let
        val {sign, decpt, digits} = fcvt (value, prec)
      in
        insertSignAndDot (sign, decpt, digits, prec)
      end

  fun fmtSCI' ({sign, decpt, digits}, prec) =
      let
        val exp = decpt - 1
        val str = insertSignAndDot (sign, 1, digits, prec)
      in
        appendExponent (str, #"~", exp)
      end

  fun fmtSCI prec value =
      fmtSCI' (ecvt (value, prec + 1), prec)

  fun fmtGEN prec value =
      let
        val x as {sign, decpt, digits} = ecvt (value, prec)
      in
        if ~4 < decpt andalso decpt <= prec
        then insertSignAndDot (sign, decpt, digits, 1)
        else fmtSCI' (x, 0)
      end

  fun fmtEXACT value =
      case exactCvt value of
        {sign = true, decpt = 1, digits = "0"} => "~0.0"
      | {sign = false, decpt = 1, digits = "0"} => "0.0"
      | {sign, decpt, digits} =>
        let
          val str = insertSignAndDot (sign, 0, digits, 0)
        in
          if decpt = 0 then str else appendExponent (str, #"~", decpt)
        end

  fun stringToDigits str =
      let
        fun loop (i, z) =
            if 0 > i
            then z
            else let val c = Array.sub_unsafe (String.castToArray str, i)
                     val n = Char.ord c - 0x30
                 in loop (i - 1, n::z)
                 end
      in
        loop (String.size str - 1, nil)
      end

  fun digitsToString (sign, digits) =
      let
        fun length (nil : int list, z) = z
          | length (h::t, z) = length (t, Int32.add (z, 1))
        val len = length (digits, 3) handle Overflow => raise Size
        val buf = String.alloc len
        fun loop (nil : int list, i) = SOME buf
          | loop (h::t, i) =
            if h < 0 orelse 9 < h
            then NONE
            else (Array.update_unsafe
                    (String.castToArray buf, i,
                     Word8.castToChar (Word8.add (Word8.fromInt32 h, 0wx30)));
                  loop (t, i + 1))
      in
        Array.update_unsafe
          (String.castToArray buf, 0, if sign then #"-" else #"+");
        Array.update_unsafe (String.castToArray buf, 1, #"0");
        Array.update_unsafe (String.castToArray buf, 2, #".");
        loop (digits, 3)
      end

  fun fmt format =
      let
        val formatFn =
            case format of
              StringCvt.EXACT => fmtEXACT
            | StringCvt.SCI NONE => fmtSCI 6
            | StringCvt.SCI (SOME prec) =>
              if prec < 0 then raise Size else fmtSCI prec
            | StringCvt.FIX NONE => fmtFIX 6
            | StringCvt.FIX (SOME prec) =>
              if prec < 0 then raise Size else fmtFIX prec
            | StringCvt.GEN NONE => fmtGEN 12
            | StringCvt.GEN (SOME prec) =>
              if prec < 1 then raise Size else fmtGEN prec
      in
        fn x =>
           let
             val clsid = SMLSharp_RealClass.classReal x
           in
             case SMLSharp_RealClass.class clsid of
               IEEEReal.INF =>
               if SMLSharp_RealClass.signBit clsid then "~inf" else "inf"
             | IEEEReal.NAN => "nan"
             | _ => formatFn x
           end
      end

  fun toDecimal x =
      let
        val clsid = SMLSharp_RealClass.classReal x
        val class = SMLSharp_RealClass.class clsid
        fun ret () =
            {exp = 0,
             digits = [],
             sign = SMLSharp_RealClass.signBit clsid,
             class = class}
      in
        case class of
          IEEEReal.ZERO => ret ()
        | IEEEReal.NAN => ret ()
        | IEEEReal.INF => ret ()
        | _ =>
          let
            val {decpt, digits, sign} = exactCvt x
          in
            {exp = decpt, digits = stringToDigits digits,
             sign = sign, class = class}
          end
      end

  fun fromDecimal ({exp, digits, sign, class}:IEEEReal.decimal_approx) =
      case class of
        IEEEReal.ZERO => SOME (if sign then ~0.0 else 0.0)
      | IEEEReal.NAN =>
        SOME (copySign (Real64.div (0.0, 0.0),
                        if sign then ~1.0 else 1.0))
      | IEEEReal.INF =>
        SOME (if sign
              then Real64.div (~1.0, 0.0)
              else Real64.div (1.0, 0.0))
      | _ =>
        case digitsToString (sign, digits) of
          NONE => NONE
        | SOME s => SOME (strtod (appendExponent (s, #"-", exp)))

  end (* local *)

  fun scan getc strm =
      case IEEEReal.scan getc strm of
        NONE => NONE
      | SOME (dec, strm) =>
        case fromDecimal dec of
          NONE => NONE
        | SOME x => SOME (x, strm)

  fun toString x =
      fmt (StringCvt.GEN NONE) x

  fun fromString s =
      StringCvt.scanString scan s

end

structure Math = Real64.Math
structure LargeReal = Real64
structure Real = Real64
