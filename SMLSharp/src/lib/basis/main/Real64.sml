(**
 * Real64 structure.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: Real64.sml,v 1.6 2008/01/16 08:17:46 kiyoshiy Exp $
 *)
local
  structure Operations =
  struct
    type real = real
    type largeReal = real

    val zero = 0.0
    val half = 0.5
    val one = 1.0
    val negative_one = ~1.0

    fun add (x : real, y) = x + y
    fun sub (x : real, y) = x - y
    fun mul (x : real, y) = x * y
    fun op div (x : real, y) = x / y

    val precision = 53
    val maxFinite = 1.79769313486E308
    val minPos = 4.94065645841E~324
    val minNormalPos = 2.22507385851E~308

    (* ToDo : which definition is correct ? *)
    val posInf = 1.0 / 0.0
    val negInf = ~1.0 / 0.0
    val nan = 0.0 / 0.0

    val fromInt = Real.fromInt
    val toString = SMLSharp.Runtime.Real_toString
    val floor = SMLSharp.Runtime.Real_floor
    val ceil = SMLSharp.Runtime.Real_ceil
    val trunc = Real.trunc_unsafe
    val round = SMLSharp.Runtime.Real_round
    val split = SMLSharp.Runtime.Real_split
    val toManExp = SMLSharp.Runtime.Real_toManExp
    val fromManExp = SMLSharp.Runtime.Real_fromManExp
    val nextAfter = SMLSharp.Runtime.Real_nextAfter
    val copySign = SMLSharp.Runtime.Real_copySign
    val equal = Real.==
    val class = SMLSharp.Runtime.Real_class
    val dtoa = SMLSharp.Runtime.Real_dtoa
    val strtod = SMLSharp.Runtime.Real_strtod

    fun toLarge real = real
    fun fromLarge roundingMode real = real

    fun compareNormal (left : real, right) =
        if left < right
        then General.LESS
        else if right < left then General.GREATER else General.EQUAL

    structure Math = Math
  end
in
structure Real64 = RealBase(Operations)
end;
