(**
 * Real related structures.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 *
 * @author Atsushi Ohori (refactored)
 * @copyright 2010, 2011, Tohoku University.
 *)
_interface "Real32.smi"

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
  structure Real32Const =
  struct
    (* IEEE 754 single precision floating point number *)
    val radix = 2
    val precision = 24
    (* 7f 7f ff ff *)
    val maxFinite = 3.4028234e38 : SMLSharp.Real32.real
    (* 00 00 00 01 *)
    val minPos = 1.4012984e~45 : SMLSharp.Real32.real
    (* 00 80 00 00 *)
    val minNormalPos = 1.1754943e~38 : SMLSharp.Real32.real
    (* 7f 80 00 00 *)
    val posInf = SMLSharp.Real32.div (1.0, 0.0)
    (* ff 80 00 00 *)
    val negInf = SMLSharp.Real32.div (~1.0, 0.0)
    (* 40 49 0f db *)
    val pi = 3.141592653 : SMLSharp.Real32.real
    (* 40 2d f8 54 *)
    val e =  2.718281828 : SMLSharp.Real32.real
  end
  structure Math32 =
  struct
    type real = SMLSharp.Real32.real
    val pi = Real32Const.pi
    val e =  Real32Const.e
    (* ToDo: the following should be primitives. *)
    fun sqrt x =
        SMLSharp.Real32.fromReal (Math.sqrt (SMLSharp.Real32.toReal x))
    fun sin x =
        SMLSharp.Real32.fromReal (Math.sin (SMLSharp.Real32.toReal x))
    fun cos x =
        SMLSharp.Real32.fromReal (Math.cos (SMLSharp.Real32.toReal x))
    fun tan x =
        SMLSharp.Real32.fromReal (Math.tan (SMLSharp.Real32.toReal x))
    fun asin x =
        SMLSharp.Real32.fromReal (Math.asin (SMLSharp.Real32.toReal x))
    fun acos x =
        SMLSharp.Real32.fromReal (Math.acos (SMLSharp.Real32.toReal x))
    fun atan x =
        SMLSharp.Real32.fromReal (Math.atan (SMLSharp.Real32.toReal x))
    fun atan2 (x, y) =
        SMLSharp.Real32.fromReal (Math.atan2 (SMLSharp.Real32.toReal x,
                                              SMLSharp.Real32.toReal y))
    fun exp x =
        SMLSharp.Real32.fromReal (Math.exp (SMLSharp.Real32.toReal x))
    fun pow (x, y) =
        SMLSharp.Real32.fromReal (Math.pow (SMLSharp.Real32.toReal x,
                                            SMLSharp.Real32.toReal y))
    fun ln x =
        SMLSharp.Real32.fromReal (Math.ln (SMLSharp.Real32.toReal x))
    fun log10 x =
        SMLSharp.Real32.fromReal (Math.log10 (SMLSharp.Real32.toReal x))
    fun sinh x =
        SMLSharp.Real32.fromReal (Math.sinh (SMLSharp.Real32.toReal x))
    fun cosh x =
        SMLSharp.Real32.fromReal (Math.cosh (SMLSharp.Real32.toReal x))
    fun tanh x =
        SMLSharp.Real32.fromReal (Math.tanh (SMLSharp.Real32.toReal x))
  end (* Math32 *)

in
structure Real32 : sig
  type real = SMLSharp.Real32.real
  structure Math : MATH where type real = real
  val radix : int
  val precision : int
  val maxFinite : real
  val minPos : real
  val minNormalPos : real
  val posInf : real
  val negInf : real
  val + : real * real -> real
  val - : real * real -> real
  val * : real * real -> real
  val / : real * real -> real
  val rem : real * real -> real
  val *+ : real * real * real -> real
  val *- : real * real * real -> real
  val ~ : real -> real
  val abs : real -> real
  val min : real * real -> real
  val max : real * real -> real
  val sign : real -> int
  val signBit : real -> bool
  val sameSign : real * real -> bool
  val copySign : real * real -> real
  val compare : real * real -> order
  val compareReal : real * real -> IEEEReal.real_order
  val < : real * real -> bool
  val <= : real * real -> bool
  val > : real * real -> bool
  val >= : real * real -> bool
  val == : real * real -> bool
  val != : real * real -> bool
  val ?= : real * real -> bool
  val unordered : real * real -> bool
  val isFinite : real -> bool
  val isNan : real -> bool
  val isNormal : real -> bool
  val class : real -> IEEEReal.float_class
  val toManExp : real -> {man : real, exp : int}
  val fromManExp : {man : real, exp : int} -> real
  val split : real -> {whole : real, frac : real}
  val realMod : real -> real
  val nextAfter : real * real -> real
  val checkFloat : real -> real
  val realFloor : real -> real
  val realCeil : real -> real
  val realTrunc : real -> real
  val realRound : real -> real
  val floor : real -> int
  val ceil : real -> int
  val trunc : real -> int
  val round : real -> int
  val toInt : IEEEReal.rounding_mode -> real -> int
  val toLargeInt : IEEEReal.rounding_mode -> real -> LargeInt.int
  val fromInt : int -> real
  val fromLargeInt : LargeInt.int -> real
  val toLarge : real -> LargeReal.real
  val fromLarge : IEEEReal.rounding_mode -> LargeReal.real -> real
  val fmt : StringCvt.realfmt -> real -> string
  val toString : real -> string
  val scan : (char, 'a) StringCvt.reader -> (real, 'a) StringCvt.reader
  val fromString : string -> real option
  val toDecimal : real -> IEEEReal.decimal_approx
  val fromDecimal : IEEEReal.decimal_approx -> real option
end =
struct
  type real = SMLSharp.Real32.real
  structure Math = Math32
  val radix = Real32Const.radix
  val precision = Real32Const.precision
  val maxFinite = Real32Const.maxFinite
  val minPos = Real32Const.minPos
  val minNormalPos = Real32Const.minNormalPos
  val posInf = Real32Const.posInf
  val negInf = Real32Const.negInf
  val op + = SMLSharp.Real32.add
  val op - = SMLSharp.Real32.sub
  val op * = SMLSharp.Real32.mul
  val op / = SMLSharp.Real32.div
  val rem = SMLSharp.Real32.rem
  fun *+ (r1, r2, r3) = r1 * r2 + r3
  fun *- (r1, r2, r3) = r1 * r2 - r3
  val op ~ = SMLSharp.Real32.neg
  val abs = SMLSharp.Real32.abs
  fun sign x = RealClass.sign (RealClass.classFloat x)
  fun signBit x = RealClass.signBit (RealClass.classFloat x)
  fun sameSign (x, y) = signBit x = signBit y
  val copySign =
      _import "copysignf"
      : __attribute__((pure,no_callback)) (real, real) -> real
  fun compareReal (x, y) =
      if SMLSharp.Real32.lt (x, y) then IEEEReal.LESS
      else if SMLSharp.Real32.gt (x, y) then IEEEReal.GREATER
      else if SMLSharp.Real32.equal (x, y) then IEEEReal.EQUAL
      else IEEEReal.UNORDERED
  fun compare (x, y) =
      case compareReal (x, y) of
        IEEEReal.UNORDERED => raise IEEEReal.Unordered
      | IEEEReal.LESS => LESS
      | IEEEReal.EQUAL => EQUAL
      | IEEEReal.GREATER => GREATER
  val op < = SMLSharp.Real32.lt
  val op <= = SMLSharp.Real32.lteq
  val op > = SMLSharp.Real32.gt
  val op >= = SMLSharp.Real32.gteq
  val == = SMLSharp.Real32.equal
  fun != x = if == x then false else true
  val ?= = SMLSharp.Real32.unorderedOrEqual
  fun isFinite x = RealClass.isFinite (RealClass.classFloat x)
  fun isNan x = RealClass.isNan (RealClass.classFloat x)
  fun unordered (x, y) = isNan x orelse isNan y
  fun isNormal x = RealClass.isNormal (RealClass.classFloat x)
  fun class x = RealClass.class (RealClass.classFloat x)
  fun min (x, y) =
      if SMLSharp.Real32.lteq (x, y) then x else if isNan x then y else x
  fun max (x, y) =
      if SMLSharp.Real32.gteq (x, y) then x else if isNan x then y else x
  local
    val frexpf =
        _import "frexpf"
        : __attribute__((pure,no_callback)) (real, int ref) -> real
    val ldexpf =
        _import "ldexpf"
        : __attribute__((pure,no_callback)) (real, int) -> real
    val modff =
        _import "modff"
        : __attribute__((pure,no_callback)) (real, real ref) -> real
  in
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
  end

  fun realMod x = #frac (split x)

  val nextAfter =
      _import "nextafterf"
      : __attribute__((pure,no_callback)) (real, real) -> real

  fun checkFloat x =
      case class x of
        IEEEReal.INF => raise Overflow
      | IEEEReal.NAN => raise Div (* Domain? This is a bug of Basis spec? *)
      | _ => x

  val realFloor =
      _import "floorf"
      : __attribute__((pure,no_callback)) real -> real
  val realCeil =
      _import "ceilf"
      : __attribute__((pure,no_callback)) real -> real
  val realRound =
      _import "roundf"
      : __attribute__((pure,no_callback)) real -> real
  val realTrunc =
      _import "truncf"
      : __attribute__((pure,no_callback)) real -> real

  fun floor x =
      if isNan x then raise Domain
      else SMLSharp.Real32.trunc_unsafe (realFloor x)
  fun ceil x =
      if isNan x then raise Domain
      else SMLSharp.Real32.trunc_unsafe (realCeil x)
  fun trunc x =
      if isNan x then raise Domain
      else SMLSharp.Real32.trunc_unsafe x
  fun round x =
      if isNan x then raise Domain
      else SMLSharp.Real32.trunc_unsafe (realTrunc x)

  fun toInt mode x =
      case mode of
        IEEEReal.TO_NEGINF => floor x
      | IEEEReal.TO_POSINF => ceil x
      | IEEEReal.TO_ZERO => trunc x
      | IEEEReal.TO_NEAREST => round x

  fun toLargeInt mode x =
      Real.toLargeInt mode (SMLSharp.Real32.toReal x)
  val fromInt = SMLSharp.Real32.fromInt
  fun fromLargeInt x =
      SMLSharp.Real32.fromReal (Real.fromLargeInt x)
  val toLarge = SMLSharp.Real32.toReal
  fun fromLarge mode x =
      raise Fail "FIXME: Real32.fromLarge: not implemented yet"
  fun fmt format x =
      Real.fmt format (SMLSharp.Real32.toReal x)
  fun toString x =
      Real.toString (SMLSharp.Real32.toReal x)
  fun scan getc strm =
      case Real.scan getc strm of
        NONE => NONE
      | SOME (x, strm) => SOME (SMLSharp.Real32.fromReal x, strm)
  fun fromString s =
      StringCvt.scanString scan s
  fun toDecimal x =
      Real.toDecimal (SMLSharp.Real32.toReal x)
  fun fromDecimal x =
      case Real.fromDecimal x of
        NONE => NONE
      | SOME x => SOME (SMLSharp.Real32.fromReal x)

end (* Real32 *)
end (* local *)
