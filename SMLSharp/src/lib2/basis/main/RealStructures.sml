(**
 * Real related structures.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @copyright 2010, 2011, Tohoku University.
 *)
_interface "RealStructures.smi"

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

structure RealStructures :> sig

  structure LargeReal : sig
    (* same as REAL except LargeReal. *)
    type real
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
    val toLarge : real -> (*LargeReal.*)real
    val fromLarge : IEEEReal.rounding_mode -> (*LargeReal.*)real -> real
    val fmt : StringCvt.realfmt -> real -> string
    val toString : real -> string
    val scan : (char, 'a) StringCvt.reader -> (real, 'a) StringCvt.reader
    val fromString : string -> real option
    val toDecimal : real -> IEEEReal.decimal_approx
    val fromDecimal : IEEEReal.decimal_approx -> real option
  end

  structure Real : sig
    (* same as REAL *)
    type real
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
  end
  where type real = SMLSharp.Real.real

  structure Real32 : sig
    type real
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
  end
  where type real = SMLSharp.Real32.real

  structure Math : MATH
    where type real = Real.real

end =
struct

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

  structure Math =
  struct
    open RealConst
    type real = real

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

  structure Math32 =
  struct
    open Real32Const
    type real = SMLSharp.Real32.real
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

(*
  structure RealPrim =
  struct

    val Real_fromManExp =
        _import "ldexp"
        : __attribute__((pure,no_callback)) (real, int) -> real
    val Real_copySign =
        _import "copysign"
        : __attribute__((pure,no_callback)) (real, real) -> real
    val Real_nextAfter =
        _import "nextafter"
        : __attribute__((pure,no_callback)) (real, real) -> real
    val Float_fromManExp =
        _import "ldexpf"
        : __attribute__((pure,no_callback))
          (SMLSharp.Real32.real, int) -> SMLSharp.Real32.real
    val Float_copySign =
        _import "copysignf"
        : __attribute__((pure,no_callback))
          (SMLSharp.Real32.real, SMLSharp.Real32.real) -> SMLSharp.Real32.real
    val Float_nextAfter =
        _import "nextafterf"
        : __attribute__((pure,no_callback))
          (SMLSharp.Real32.real, SMLSharp.Real32.real) -> SMLSharp.Real32.real
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

  end (* RealPrim *)
*)

  structure RealClass :> sig
    type class
    val classReal : real -> class
    val classFloat : SMLSharp.Real32.real -> class
    val class : class -> IEEEReal.float_class
    val isFinite : class -> bool
    val isInf : class -> bool
    val isNan : class -> bool
    val isNormal : class -> bool
    val sign : class -> int
    val signBit : class -> bool
  end =
  struct

    (*
     * Following constants are defined in nativeruntime/prim.c.
     *
     * #define IEEEREAL_CLASS_SNAN     1   /* signaling NaN */
     * #define IEEEREAL_CLASS_QNAN     2   /* quiet NaN */
     * #define IEEEREAL_CLASS_INF      3   /* infinity */
     * #define IEEEREAL_CLASS_DENORM   4   /* denormal */
     * #define IEEEREAL_CLASS_ZERO     5   /* zero */
     * #define IEEEREAL_CLASS_NORM     6   /* normal */
     * #define IEEEREAL_CLASS_UNKNOWN  0
     *
     * sign of class integer means sign bit information.
     *)
    type class = int

    val classReal =
        _import "prim_Real_class"
        : __attribute__((pure,no_callback)) real -> class
    val classFloat =
        _import "prim_Float_class"
        : __attribute__((pure,no_callback)) SMLSharp.Real32.real -> class

    fun class c =
        case SMLSharp.Int.abs c of
          1 => IEEEReal.NAN
        | 2 => IEEEReal.NAN
        | 3 => IEEEReal.INF
        | 4 => IEEEReal.SUBNORMAL
        | 5 => IEEEReal.ZERO
        | 6 => IEEEReal.NORMAL
        | _ => raise Fail "BUG: RealClass.toIEEERealClass"
    fun isFinite class =
        class >= 4 orelse class <= ~4   (* denormal, zero, or normal *)
    fun isInf class =
        class = 3 orelse class = ~3     (* infinity *)
    fun isNan class =
        ~2 <= class andalso class < 2   (* SNaN or QNaN *)
    fun isNormal class =
        class = 6 orelse class = ~6     (* isNormal *)
    fun sign class =
        if isNan class then raise Domain
        else if class = 5 then 0        (* zero *)
        else if class < 0 then ~1 else 1
    fun signBit class = class < 0

  end (* RealClass *)

  structure Real =
  struct
    open RealConst

    type real = real
    structure Math = Math

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

    fun floor x = raise Fail "FIXME: Real.floor: not implemented yet"
    fun ceil x = raise Fail "FIXME: Real.ceil: not implemented yet"
    fun trunc x = raise Fail "FIXME: Real.trunc: not implemented yet"
    fun round x = raise Fail "FIXME: Real.round: not implemented yet"

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
    fun fmt format x =
        raise Fail "FIXME: Real.fmt: not implemented yet"
    fun toString x =
        fmt (StringCvt.GEN NONE) x
    fun scan getc strm =
        raise Fail "FIXME: Real.scan: not implemented yet"
    fun fromString s =
        StringCvt.scanString scan s
    fun toDecimal x =
        raise Fail "FIXME: Real.toDecimal: not implemented yet"
    fun fromDecimal x =
        raise Fail "FIXME: Real.fromDecimal: not implemented yet"

  end (* Real *)

  structure LargeReal = Real

  structure Real32 =
  struct
    open Real32Const

    type real = SMLSharp.Real32.real
    structure Math = Math32

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
    fun isNormal x = RealClass.isNormal (RealClass.classFloat x)
    fun class x = RealClass.class (RealClass.classFloat x)
    fun unordered (x, y) = isNan x orelse isNan y
    fun min (x, y) =
        if SMLSharp.Real32.lteq (x, y) then x else if isNan x then y else x
    fun max (x, y) =
        if SMLSharp.Real32.gteq (x, y) then x else if isNan x then y else x

    val frexpf =
        _import "frexpf"
        : __attribute__((pure,no_callback)) (real, int ref) -> real
    val ldexpf =
        _import "ldexpf"
        : __attribute__((pure,no_callback)) (real, int) -> real
    val modff =
        _import "modff"
        : __attribute__((pure,no_callback)) (real, real ref) -> real

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

    fun floor x = raise Fail "FIXME: Real.floor: not implemented yet"
    fun ceil x = raise Fail "FIXME: Real.ceil: not implemented yet"
    fun trunc x = raise Fail "FIXME: Real.trunc: not implemented yet"
    fun round x = raise Fail "FIXME: Real.round: not implemented yet"

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

end (* RealStructures *)

in

open RealStructures

val real = Real.fromInt

end (* local *)
