(**
 * Real related structures.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @author Atsushi Ohori (refactored)
 * @copyright 2010, 2011, Tohoku University.
 *)
(*
 2012-1-7 ohori.
 Separated from RealStructure.sml/smi.
 This is the fundamental structure that should be defined directly.
*)

_interface "Real.smi"

local
  infix 7 * / div mod
  infix 6 + -
  infixr 5 ::
  infix 4 = <> > >= < <=
  val op + = SMLSharp.Int.add
  val op - = SMLSharp.Int.sub
  val op > = SMLSharp.Int.gt
  val op < = SMLSharp.Int.lt
  val op <= = SMLSharp.Int.lteq
  val op >= = SMLSharp.Int.gteq

  structure RealConst =
  struct
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
    val posInf = SMLSharp.Real.div (1.0, 0.0)
    (* fff 0 00 00 00 00 00 00 *)
    val negInf = SMLSharp.Real.div (~1.0, 0.0)
    (* 400 9 21 fb 54 44 2d 18 *)
    val pi = 3.141592653589793 : real
    (* 400 5 bf 0a 8b 14 57 69 *)
    val e = 2.718281828459045 : real
  end
in
structure Math =
struct
  type real = real
  val pi = RealConst.pi
  val e = RealConst.e
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
end (* Math *)

structure Real =
struct
  type real = real
  structure Math = Math
  val radix = RealConst.radix
  val precision = RealConst.precision
  val maxFinite = RealConst.maxFinite
  val minPos = RealConst.minPos
  val minNormalPos = RealConst.minNormalPos
  val posInf = RealConst.posInf
  val negInf = RealConst.negInf
  val op + = SMLSharp.Real.add
  val op - = SMLSharp.Real.sub
  val op * = SMLSharp.Real.mul
  val op / = SMLSharp.Real.div
  (* NOTE: Real.rem is not same as remainder(3) defined in C99. *)
  val rem = SMLSharp.Real.rem
  fun *+ (r1, r2, r3) = r1 * r2 + r3
  fun *- (r1, r2, r3) = r1 * r2 - r3
  val op ~ = SMLSharp.Real.neg
  val abs = SMLSharp.Real.abs
  fun sign x = RealClass.sign (RealClass.classReal x)
  fun signBit x = RealClass.signBit (RealClass.classReal x)
  fun sameSign (x, y) = signBit x = signBit y
  val copySign =
      _import "copysign"
      : __attribute__((pure,no_callback)) (real, real) -> real
  fun compareReal (x, y) =
      if SMLSharp.Real.lt (x, y) then IEEEReal.LESS
      else if SMLSharp.Real.gt (x, y) then IEEEReal.GREATER
      else if SMLSharp.Real.equal (x, y) then IEEEReal.EQUAL
      else IEEEReal.UNORDERED
  fun compare (x, y) =
      case compareReal (x, y) of
        IEEEReal.UNORDERED => raise IEEEReal.Unordered
      | IEEEReal.LESS => LESS
      | IEEEReal.EQUAL => EQUAL
      | IEEEReal.GREATER => GREATER
  val op < = SMLSharp.Real.lt
  val op <= = SMLSharp.Real.lteq
  val op > = SMLSharp.Real.gt
  val op >= = SMLSharp.Real.gteq
  val == = SMLSharp.Real.equal
  fun != x = if == x then false else true
  val ?= = SMLSharp.Real.unorderedOrEqual
  fun isFinite x = RealClass.isFinite (RealClass.classReal x)
  fun isNan x = RealClass.isNan (RealClass.classReal x)
  fun unordered (x, y) = isNan x orelse isNan y
  fun isNormal x = RealClass.isNormal (RealClass.classReal x)
  fun class x = RealClass.class (RealClass.classReal x)
  fun min (x, y) =
      if SMLSharp.Real.lteq (x, y) then x else if isNan x then y else x
  fun max (x, y) =
      if SMLSharp.Real.gteq (x, y) then x else if isNan x then y else x

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
  val realRound =
      _import "round"
      : __attribute__((pure,no_callback)) real -> real
  val realTrunc =
      _import "trunc"
      : __attribute__((pure,no_callback)) real -> real

  fun floor x =
      if isNan x then raise Domain
      else SMLSharp.Real.trunc_unsafe (realFloor x)
  fun ceil x =
      if isNan x then raise Domain
      else SMLSharp.Real.trunc_unsafe (realCeil x)
  fun trunc x =
      if isNan x then raise Domain
      else SMLSharp.Real.trunc_unsafe x
  fun round x =
      if isNan x then raise Domain
      else SMLSharp.Real.trunc_unsafe (realTrunc x)

  fun toInt mode x =
      case mode of
        IEEEReal.TO_NEGINF => floor x
      | IEEEReal.TO_POSINF => ceil x
      | IEEEReal.TO_ZERO => trunc x
      | IEEEReal.TO_NEAREST => round x

  fun toLargeInt mode x =
      raise Fail "FIXME: Real.toLargeInt: not implemented yet"
  val fromInt = SMLSharp.Real.fromInt
  fun fromLargeInt x =
      raise Fail "FIXME: Real.fromLargeInt: not implemented yet"
  fun toLarge x = x : real
  fun fromLarge (mode:IEEEReal.rounding_mode) x = x : real

  local 
    val dtoa =
        _import "sml_dtoa"
        : __attribute__((no_callback))
          (real, int, int, int ref, int ref, char ptr ptr) -> char ptr
    val freedtoa =
        _import "sml_freedtoa"
        : __attribute__((no_callback)) char ptr -> unit
    val strtod =
        _import "sml_strtod"
        : __attribute__((pure,no_callback)) (string, char ptr ptr) -> real
    fun charToDigit nil = nil
      | charToDigit (h::t) =
        SMLSharp.Int.sub (SMLSharp.Char.ord h, 0x30) :: charToDigit t
    fun readDigits p =
        case SMLSharp.Pointer.deref_char p of
          #"\000" => nil
        | c => c :: readDigits (SMLSharp.Pointer.advance (p, 1))
    fun realToDecimal (mode, ndigit, x) =
        let
          val decpt = ref 0
          val sign = ref 0
          val s = dtoa (x, mode, ndigit, decpt, sign,
                        SMLSharp.Pointer.fromUnitPtr _NULL)
          val digits = readDigits s
          val _ = freedtoa s
        in
          {decpt = !decpt, digits = digits,
           sign = if !sign = 0 then false else true}
        end

    fun fmtFrac fillZero prec frac =
        let
          val frac =
              if fillZero then StringCvt.padRight #"0" prec frac else frac
        in
          case frac of "" => ".0" | _ => String.^ (".", frac)
        end
    fun fmtFix fillZero prec x =
    (* 2012-3-27 ohori
        Fixed the bug #  Real.toString 10.0;
        uncaught exception: Subscript
      dtoa return the non-zero part of the digits.
      dotoa 10.0 yields 1 for digits.
      2012-3-1 ohori
       Fixed the bug 
        # 0.1 ;
        val it = .1 : real
     *)
        let
          fun decompose(s,n) =
              let
                val length = String.size s
              in
                if SMLSharp.Int.gteq(length, n) then 
                  case n of 
                    0 => ("0", s)
                  | _ => 
                    let
                      val (a,b) = Substring.splitAt(Substring.full s,n)
                    in
                      (Substring.string a, Substring.string b)
                    end
                else
                  (StringCvt.padRight #"0" n s, "")
              end
          val _ = if SMLSharp.Int.lt (prec, 0) then raise Size else ()
          val {decpt, digits, sign} = realToDecimal (3, prec, x)
          val digits = implode digits
          val (whole, frac) = decompose (digits, decpt)
          val frac = fmtFrac fillZero prec frac
          val sign = if sign then "~" else "" 
        in
          String.concat [sign, whole, frac]
        end
    fun fmtSci fillZero prec x =
        let
          val _ = if SMLSharp.Int.lt (prec, 0) then raise Size else ()
          val ndigit = SMLSharp.Int.add (prec, 1)
          val {decpt, digits, sign} = realToDecimal (2, ndigit, x)
          val exp = SMLSharp.Int.add (decpt, 1)
          val (whole, frac) =
              case digits of
                h::t => (String.str h, implode t)
              | nil => ("0", "")
          val frac = fmtFrac fillZero prec frac
          val sign = if sign then "~" else "" 
        in
          String.concat [sign, whole, frac, "E", Int.toString exp]
        end

    fun fmtGen prec x =
        let
          val _ = if SMLSharp.Int.lt (prec, 1) then raise Size else ()
          val {decpt, ...} = realToDecimal (2, 1, x)
        in
          if SMLSharp.Int.lteq (decpt, ~4)
             orelse SMLSharp.Int.gt (decpt, prec)
          then fmtSci false prec x
          else fmtFix false prec x
        end

  in
  fun toDecimal x =
      let
        val clsid = RealClass.classReal x
        val class = RealClass.class clsid
        fun ret () =
            {exp = 0, digits = [],
             sign = if RealClass.sign clsid = 1 then false else true,
             class = class}
      in
        case class of
          IEEEReal.ZERO => ret ()
        | IEEEReal.NAN => ret ()
        | IEEEReal.INF => ret ()
        | _ =>
          let
            val {decpt, digits, sign} = realToDecimal (0, 0, x)
          in
            {exp = decpt, digits = charToDigit digits,
             sign = sign, class = class}
          end
      end

  fun fromDecimal ({exp, digits, sign, class}:IEEEReal.decimal_approx) =
      let
        val sign = if sign then ~1.0 else 1.0
      in
        case class of
          IEEEReal.ZERO => SOME (copySign (0.0, sign))
        | IEEEReal.NAN => SOME (copySign (SMLSharp.Real.div (1.0, 0.0), sign))
        | IEEEReal.INF => SOME (copySign (RealConst.posInf, sign))
        | _ =>
          let
            val dec = {exp=exp, digits=digits, sign=false, class=class}
            val s = IEEEReal.toString dec
            val r = strtod (s, SMLSharp.Pointer.fromUnitPtr _NULL)
          in
            if (== (r, RealConst.posInf) orelse == (r, 0.0))
               andalso SOME (SMLSharpRuntime.errno ())
                       = SMLSharpRuntime.syserror "range"
            then NONE
            else SOME (copySign (r, sign))
          end
      end

  fun fmt format x =
      let
        val clsid = RealClass.classReal x
      in
        case RealClass.class clsid of
          IEEEReal.INF => if RealClass.sign clsid = 1 then "inf" else "~inf"
        | IEEEReal.NAN => "nan"
        | _ =>
          case format of
            StringCvt.EXACT =>
            IEEEReal.toString (toDecimal x)
          | StringCvt.SCI prec =>
            fmtSci true (case prec of NONE => 6 | SOME x => x) x
          | StringCvt.FIX prec =>
            fmtFix true (case prec of NONE => 6 | SOME x => x) x
          | StringCvt.GEN prec =>
            fmtGen (case prec of NONE => 12 | SOME x => x) x
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

end (* Real *)
end

structure LargeReal = Real
structure Real64 = Real

val real = Real.fromInt
val ceil = Real.ceil
val floor = Real.floor
val round = Real.round
val trunc = Real.trunc
