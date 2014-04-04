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
structure Real = SMLSharp_Builtin.Real
structure Pointer = SMLSharp_Builtin.Pointer
structure Array = SMLSharp_Builtin.Array
structure String = SMLSharp_Builtin.String
structure Word8 = SMLSharp_Builtin.Word8
structure Char = SMLSharp_Builtin.Char

structure Real =
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
  val posInf = Real.div (1.0, 0.0)
  (* fff 0 00 00 00 00 00 00 *)
  val negInf = Real.div (~1.0, 0.0)

  structure Math =
  struct
    type real = real

    (* 400 9 21 fb 54 44 2d 18 *)
    val pi = 3.141592653589793 : real
    (* 400 5 bf 0a 8b 14 57 69 *)
    val e = 2.718281828459045 : real

    val sqrt =
        _import "sqrt"
        : __attribute__((pure,no_callback)) real -> real
    val sin =
        _import "sin"
        : __attribute__((pure,no_callback)) real -> real
    val cos =
        _import "cos"
        : __attribute__((pure,no_callback)) real -> real
    val tan =
        _import "tan"
        : __attribute__((pure,no_callback)) real -> real
    val asin =
        _import "asin"
        : __attribute__((pure,no_callback)) real -> real
    val acos =
        _import "acos"
        : __attribute__((pure,no_callback)) real -> real
    val atan =
        _import "atan"
        : __attribute__((pure,no_callback)) real -> real
    val atan2 =
        _import "atan2"
        : __attribute__((pure,no_callback)) (real, real) -> real
    val exp =
        _import "exp"
        : __attribute__((pure,no_callback)) real -> real
    val pow =
        _import "pow"
        : __attribute__((pure,no_callback)) (real, real) -> real
    val ln =
        _import "log"
        : __attribute__((pure,no_callback)) real -> real
    val log10 =
        _import "log10"
        : __attribute__((pure,no_callback)) real -> real
    val sinh =
        _import "sinh"
        : __attribute__((pure,no_callback)) real -> real
    val cosh =
        _import "cosh"
        : __attribute__((pure,no_callback)) real -> real
    val tanh =
        _import "tanh"
        : __attribute__((pure,no_callback)) real -> real
  end

  val op + = Real.add
  val op - = Real.sub
  val op * = Real.mul
  val op / = Real.div
  (* NOTE: Real.rem is not same as remainder(3) defined in C99. *)
  val rem = Real.rem
  val ~ = Real.neg
  val abs = Real.abs
  val op < = Real.lt
  val op <= = Real.lteq
  val op > = Real.gt
  val op >= = Real.gteq
  val == = Real.equal
  val != = Real.notEqual
  val ?= = Real.ueq
  val isNan = Real.isNan
  val trunc = Real.trunc
  val fromInt = Real.fromInt_unsafe

  fun *+ (r1, r2, r3) = r1 * r2 + r3
  fun *- (r1, r2, r3) = r1 * r2 - r3

  fun min (x, y) =
      if isNan x then y
      else if isNan y then x
      else if Real.lteq (x, y) then x else y
  fun max (x, y) =
      if isNan x then y
      else if isNan y then x
      else if Real.lteq (x, y) then y else x
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
      : __attribute__((pure,no_callback)) (real, real) -> real

  fun compareReal (x, y) =
      if Real.lt (x, y) then IEEEReal.LESS
      else if Real.gt (x, y) then IEEEReal.GREATER
      else if Real.equal (x, y) then IEEEReal.EQUAL
      else IEEEReal.UNORDERED

  fun compare (x, y) =
      case compareReal (x, y) of
        IEEEReal.UNORDERED => raise IEEEReal.Unordered
      | IEEEReal.LESS => General.LESS
      | IEEEReal.EQUAL => General.EQUAL
      | IEEEReal.GREATER => General.GREATER

  val frexp =
      _import "frexp"
      : __attribute__((pure,no_callback)) (real, int ref) -> real
  val ldexp =
      _import "ldexp"
      : __attribute__((pure,no_callback)) (real, int) -> real
  val modf =
      _import "modf"
      : __attribute__((pure,no_callback)) (real, real ref) -> real

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

  val nextAfter =
      _import "nextafter"
      : __attribute__((pure,no_callback)) (real, real) -> real

  fun checkFloat x =
      case class x of
        IEEEReal.INF => raise Overflow
      | IEEEReal.NAN => raise Div (* Domain? This is a bug of Basis spec? *)
      | _ => x

  val realFloor =
      _import "floor"
      : __attribute__((pure,no_callback)) real -> real
  val realCeil =
      _import "ceil"
      : __attribute__((pure,no_callback)) real -> real
  val realTrunc =
      _import "trunc"
      : __attribute__((pure,no_callback)) real -> real

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

  fun floor x = Real.trunc (realFloor x)
  fun ceil x = Real.trunc (realCeil x)
  fun round x = Real.trunc (realRound x)

  fun toInt mode x =
      if isNan x then raise Domain else
      case mode of
        IEEEReal.TO_NEGINF => floor x
      | IEEEReal.TO_POSINF => ceil x
      | IEEEReal.TO_ZERO => trunc x
      | IEEEReal.TO_NEAREST => round x

  val IntInf_fromReal =
      _import "prim_IntInf_fromReal"
      : __attribute__((pure,no_callback,alloc))
        real -> SMLSharp_Builtin.IntInf.int

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
      : __attribute__((pure,no_callback))
        SMLSharp_Builtin.IntInf.int -> real

  fun toLarge x = x : real
  fun fromLarge (mode:IEEEReal.rounding_mode) x = x : real

  local
    val sml_dtoa =
        _import "sml_dtoa"
        : __attribute__((no_callback))
          (real, int, int, int ref, int ref, char ptr ptr) -> char ptr
    val sml_freedtoa =
        _import "sml_freedtoa"
        : __attribute__((no_callback)) char ptr -> ()
    val str_new =
        _import "sml_str_new"
        : __attribute__((no_callback,alloc)) char ptr -> string

    fun dtoa (mode, ndigit, value) =
        let
          val decpt = ref 0
          val sign = ref 0
          val s = sml_dtoa (value, mode, ndigit, decpt, sign,
                            Pointer.fromUnitPtr _NULL)
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
        : __attribute__((pure,no_callback)) (string, char ptr ptr) -> real
  in
  fun strtod str = sml_strtod (str, Pointer.fromUnitPtr _NULL)
  end (* local *)

  local
    val op + = SMLSharp_Builtin.Int.add_unsafe
    val op - = SMLSharp_Builtin.Int.sub_unsafe
    val op < = SMLSharp_Builtin.Int.lt
    val op > = SMLSharp_Builtin.Int.gt
    val op >= = SMLSharp_Builtin.Int.gteq
    val op <= = SMLSharp_Builtin.Int.lteq

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

    fun insertSignAndDot (sign, decpt, digits, prec) =
        let
          val plen = if sign then 1 else 0
          val slen = String.size digits
        in
          if decpt > 0 then
            if decpt >= slen then
              let
                val zeroes = decpt - slen
                val frac = if prec > 0 then prec + 1 else 0
                val buflen = plen + slen + zeroes + frac
                val buf = String.alloc buflen
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
                val frac = slen - decpt
                val zeroes = if prec > frac then prec - frac else 0
                val buflen = plen + slen + 1 + zeroes
                val buf = String.alloc buflen
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
          else
            let
              val pzeroes = 0 - decpt
              val frac = pzeroes + slen
              val tzeroes = if prec > frac then prec - frac else 0
              val frac = frac + tzeroes
              val frac = if frac > 0 then frac + 1 else 0
              val buflen = plen + 1 + frac
              val buf = String.alloc buflen
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
        end

    fun appendExponent (str, exp) =
        let
          val slen = String.size str
          val elen = String.size exp
          val buf = String.alloc (slen + 1 + elen)
        in
          Array.copy_unsafe (String.castToArray str, 0,
                             String.castToArray buf, 0, slen);
          Array.update_unsafe (String.castToArray buf, slen, #"E");
          Array.copy_unsafe (String.castToArray exp, 0,
                             String.castToArray buf, slen + 1, elen);
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
          appendExponent (str, Int.toString exp)
        end

    fun fmtSCI prec value =
        fmtSCI' (ecvt (value, prec + 1), prec)

    fun fmtGEN prec value =
        let
          val x as {sign, decpt, digits} = ecvt (value, prec)
        in
          if ~5 < decpt - 1 andalso decpt <= prec
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
            if decpt = 0 then str else appendExponent (str, Int.toString decpt)
          end

    fun stringToDigits str =
        let
          fun loop (i, z) =
              if i < 0
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
            | length (h::t, z) = length (t, z + 1)
          val len = length (digits, 3)
          val buf = String.alloc len
          fun loop (nil : int list, i) = SOME buf
            | loop (h::t, i) =
              if h < 0 orelse 9 < h
              then NONE
              else (Array.update_unsafe
                      (String.castToArray buf, i,
                       Word8.castToChar (Word8.add (Word8.fromInt h, 0wx30)));
                    loop (t, i + 1))
        in
          Array.update_unsafe
            (String.castToArray buf, 0, if sign then #"-" else #"+");
          Array.update_unsafe (String.castToArray buf, 1, #"0");
          Array.update_unsafe (String.castToArray buf, 2, #".");
          loop (digits, 3)
        end

  in

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
             sign = SMLSharp_RealClass.toInt clsid < 0,
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
        SOME (copySign (Real.div (0.0, 0.0),
                        if sign then ~1.0 else 1.0))
      | IEEEReal.INF =>
        SOME (if sign
              then Real.div (~1.0, 0.0)
              else Real.div (1.0, 0.0))
      | _ =>
        case digitsToString (sign, digits) of
          NONE => NONE
        | SOME s =>
          let
            val exp = Int.toString exp
          in
            if Array.sub_unsafe (String.castToArray exp, 0) = #"~"
            then Array.update_unsafe (String.castToArray exp, 0, #"-")
            else ();
            SOME (strtod (appendExponent (s, exp)))
          end

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

structure Math = Real.Math
structure LargeReal = Real
structure Real64 = Real
