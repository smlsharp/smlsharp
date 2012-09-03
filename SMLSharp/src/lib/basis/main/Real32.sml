(**
 * Real32 structure.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: Real32.sml,v 1.2 2007/11/05 02:01:30 kiyoshiy Exp $
 *)
local
  structure Math32 =
  struct
    type real = Real32.real

    val fromReal64 = Real32.fromReal
    val toReal64 = Real32.toReal
    fun wrap1 f = fromReal64 o f o toReal64
    fun wrap2 f (x, y) = fromReal64 (f (toReal64 x, toReal64 y))

    val pi = fromReal64 Math.pi
    val e = fromReal64 Math.e
    fun sqrt x = wrap1 Math.sqrt x
    fun sin x = wrap1 Math.sin x
    fun cos x = wrap1 Math.cos x
    fun tan x = wrap1 Math.tan x
    fun asin x = wrap1 Math.asin x
    fun acos x = wrap1 Math.acos x
    fun atan x = wrap1 Math.atan x
    fun atan2 x = wrap2 Math.atan2 x
    fun exp x = wrap1 Math.exp x
    fun pow x = wrap2 Math.pow x
    fun ln x = wrap1 Math.ln x
    fun log10 x = wrap1 Math.log10 x
    fun sinh x = wrap1 Math.sinh x
    fun cosh x = wrap1 Math.cosh x
    fun tanh x = wrap1 Math.tanh x
  end

  structure Operations =
  struct
    type real = Real32.real
    type largeReal = Real64.real

    val zero = 0.0 : real
    val half = 0.5 : real
    val one = 1.0 : real
    val negative_one = ~1.0 : real

    fun add (x : real, y) = x + y
    fun sub (x : real, y) = x - y
    fun mul (x : real, y) = x * y
    fun op div (x : real, y) = x / y

    val precision = 24
    val maxFinite = 3.4028235E38 : real
    val minPos = 1.4012985E~45 : real
    val minNormalPos = 1.175494351E~38 : real

    (* ToDo : which definition is correct ? *)
    val posInf = 1.0 / 0.0 : real
    val negInf = ~1.0 / 0.0 : real
    val nan = 0.0 / 0.0 : real

    val fromInt = Real32.fromInt
    val toString = SMLSharp.Runtime.Float_toString
    val floor = SMLSharp.Runtime.Float_floor
    val ceil = SMLSharp.Runtime.Float_ceil
    val trunc = Real32.trunc_unsafe
    val round = SMLSharp.Runtime.Float_round
    val split = SMLSharp.Runtime.Float_split
    val toManExp = SMLSharp.Runtime.Float_toManExp
    val fromManExp = SMLSharp.Runtime.Float_fromManExp
    val nextAfter = SMLSharp.Runtime.Float_nextAfter
    val copySign = SMLSharp.Runtime.Float_copySign
    val equal = Real32.==
    val class = SMLSharp.Runtime.Float_class
    val dtoa = SMLSharp.Runtime.Float_dtoa
    val strtod = SMLSharp.Runtime.Float_strtod

    val toLarge = Real32.toReal
    fun fromLarge roundingMode largeReal =
        Real32.fromReal largeReal

    fun compareNormal (left : real, right : real) =
        if left < right
        then General.LESS
        else if right < left then General.GREATER else General.EQUAL

    structure Math = Math32
  end
in
structure Real32 = RealBase(Operations)
end
