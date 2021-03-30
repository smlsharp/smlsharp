(**
 * Real32
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright (C) 2021 SML# Development Team.
 *)

infix 7 * / div mod
infix 6 + -
infixr 5 ::
infix 4 = <> > >= < <=
val ! = SMLSharp_Builtin.General.!
structure Real32 = SMLSharp_Builtin.Real32

structure Real32 =
struct

  type real = real32

  structure Math =
  struct
    type real = real
    (* IEEE 754 single precision floating point number *)
    (* 40 49 0f db *)
    val pi = 3.141592653 : real32
    (* 40 2d f8 54 *)
    val e =  2.718281828 : real32
    val sqrt =
        _import "sqrtf"
        : __attribute__((pure,fast)) real -> real
    val sin =
        _import "sinf"
        : __attribute__((pure,fast)) real -> real
    val cos =
        _import "cosf"
        : __attribute__((pure,fast)) real -> real
    val tan =
        _import "tanf"
        : __attribute__((pure,fast)) real -> real
    val asin =
        _import "asinf"
        : __attribute__((pure,fast)) real -> real
    val acos =
        _import "acosf"
        : __attribute__((pure,fast)) real -> real
    val atan =
        _import "atanf"
        : __attribute__((pure,fast)) real -> real
    val atan2 =
        _import "atan2f"
        : __attribute__((pure,fast)) (real, real) -> real
    val exp =
        _import "expf"
        : __attribute__((pure,fast)) real -> real
    val pow' =
        _import "powf"
        : __attribute__((pure,fast)) (real, real) -> real
    val posInf = Real32.div (1.0, 0.0)
    val nan = Real32.mul (0.0, posInf)
    fun pow (x, y) =
        if SMLSharp_RealClass.isInf (SMLSharp_RealClass.classFloat y)
        then 
          if Real32.equal (x, 1.0) orelse Real32.equal (x, ~1.0)
          then nan
          else pow' (x, y)
        else pow' (x, y)
    val ln =
        _import "logf"
        : __attribute__((pure,fast)) real -> real
    val log10 =
        _import "log10f"
        : __attribute__((pure,fast)) real -> real
    val sinh =
        _import "sinhf"
        : __attribute__((pure,fast)) real -> real
    val cosh =
        _import "coshf"
        : __attribute__((pure,fast)) real -> real
    val tanh =
        _import "tanhf"
        : __attribute__((pure,fast)) real -> real
  end

  (* IEEE 754 single precision floating point number *)
  val radix = 2
  val precision = 24
  (* 7f 7f ff ff *)
  val maxFinite = 3.4028234e38 : real32
  (* 00 00 00 01 *)
  val minPos = 1.4012984e~45 : real32
  (* 00 80 00 00 *)
  val minNormalPos = 1.1754943e~38 : real32
  (* 7f 80 00 00 *)
  val posInf = Real32.div (1.0, 0.0)
  (* ff 80 00 00 *)
  val negInf = Real32.div (~1.0, 0.0)

  val op + = Real32.add
  val op - = Real32.sub
  val op * = Real32.mul
  val op / = Real32.div
  val rem = Real32.rem
  val ~ = Real32.neg
  val abs = Real32.abs
  val op < = Real32.lt
  val op <= = Real32.lteq
  val op > = Real32.gt
  val op >= = Real32.gteq
  val == = Real32.equal
  val != = Real32.notEqual
  val ?= = Real32.ueq
  val isNan = Real32.isNan
  val trunc = Real32.trunc
  val fromInt = SMLSharp_Builtin.Real32.fromInt32
  val toLarge = SMLSharp_Builtin.Real32.toReal64
  val fromReal64 = SMLSharp_Builtin.Real32.fromReal64

  fun *+ (r1, r2, r3) = r1 * r2 + r3
  fun *- (r1, r2, r3) = r1 * r2 - r3

  fun min (x, y) =
      if isNan x then y
      else if isNan y then x
      else if Real32.lteq (x, y) then x else y
  fun max (x, y) =
      if isNan x then y
      else if isNan y then x
      else if Real32.lteq (x, y) then y else x
  fun sign x = SMLSharp_RealClass.sign (SMLSharp_RealClass.classFloat x)
  fun signBit x = SMLSharp_RealClass.signBit (SMLSharp_RealClass.classFloat x)
  fun sameSign (x, y) = signBit x = signBit y
  fun isFinite x = SMLSharp_RealClass.isFinite (SMLSharp_RealClass.classFloat x)
  fun unordered (x, y) = isNan x orelse isNan y
  fun isNormal x = SMLSharp_RealClass.isNormal (SMLSharp_RealClass.classFloat x)
  fun class x = SMLSharp_RealClass.class (SMLSharp_RealClass.classFloat x)

  val copySign =
      _import "copysignf"
      : __attribute__((pure,fast)) (real, real) -> real

  fun compareReal (x, y) =
      if Real32.lt (x, y) then IEEEReal.LESS
      else if Real32.gt (x, y) then IEEEReal.GREATER
      else if Real32.equal (x, y) then IEEEReal.EQUAL
      else IEEEReal.UNORDERED

  fun compare (x, y) =
      case compareReal (x, y) of
        IEEEReal.UNORDERED => raise IEEEReal.Unordered
      | IEEEReal.LESS => General.LESS
      | IEEEReal.EQUAL => General.EQUAL
      | IEEEReal.GREATER => General.GREATER

  val frexpf =
      _import "frexpf"
      : __attribute__((pure,fast)) (real, int ref) -> real
  val ldexpf =
      _import "ldexpf"
      : __attribute__((pure,fast)) (real, int) -> real
  val modff =
      _import "modff"
      : __attribute__((pure,fast)) (real, real ref) -> real

  fun toManExp x =
      let val exp = ref 0
          val man = frexpf (x, exp)
      in {man = man, exp = !exp}
      end

  fun fromManExp {man, exp} =
      ldexpf (man, exp)

  fun split x =
      let val intg = ref 0.0
          val frac = modff (x, intg)
      in {whole = !intg, frac = frac}
      end

  fun realMod x = #frac (split x)

  val nextafterf = 
      _import "nextafterf"
      : __attribute__((pure,fast)) (real, real) -> real

  fun nextAfter (r, t) =
      case (class r, class t) of
	(IEEEReal.INF, IEEEReal.NAN) => nextafterf (r, t)
      | (IEEEReal.INF, _) => r
      | _ => nextafterf (r, t)

  fun checkFloat x =
      case class x of
        IEEEReal.INF => raise Overflow
      | IEEEReal.NAN => raise Div (* Domain? This is a bug of Basis spec? *)
      | _ => x

  val realFloor =
      _import "floorf"
      : __attribute__((pure,fast)) real -> real
  val realCeil =
      _import "ceilf"
      : __attribute__((pure,fast)) real -> real
  val realTrunc =
      _import "truncf"
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

  fun floor x = Real32.trunc (realFloor x)
  fun ceil x = Real32.trunc (realCeil x)
  fun round x = Real32.trunc (realRound x)

  fun toInt mode x =
      case mode of
        IEEEReal.TO_NEGINF => floor x
      | IEEEReal.TO_POSINF => ceil x
      | IEEEReal.TO_ZERO => trunc x
      | IEEEReal.TO_NEAREST => round x

  fun toLargeInt mode x =
      Real64.toLargeInt mode (toLarge x)

  fun fromLargeInt x =
      fromReal64 (Real64.fromLargeInt x)  (* FIXME *)

  fun fromLarge (mode:IEEEReal.rounding_mode) (x:LargeReal.real) : real =
      case mode of
        IEEEReal.TO_NEAREST => fromReal64 x
      | _ =>
        raise SMLSharp_Runtime.Bug "FIXME: Real32.fromLarge: not implemented"

  fun fmt format x =
      Real64.fmt format (toLarge x)

  fun toString x =
      Real64.toString (toLarge x)

  fun scan getc strm =
      case Real64.scan getc strm of
        NONE => NONE
      | SOME (x, strm) => SOME (fromReal64 x, strm)  (* FIXME *)

  fun fromString s =
      StringCvt.scanString scan s

  fun toDecimal x =
      Real64.toDecimal (toLarge x)

  fun fromDecimal x =
      case Real64.fromDecimal x of
        NONE => NONE
      | SOME x => SOME (fromReal64 x)  (* FIXME *)

end
