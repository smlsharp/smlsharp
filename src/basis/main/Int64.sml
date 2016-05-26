(**
 * Int64
 * @author SASAKI Tomohiro
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright 2014, Tohoku University.
 *)

infix 7 * / div mod
infix 6 + -
infixr 5 ::
infix 4 = <> > >= < <=
structure Int64 = SMLSharp_Builtin.Int64

structure Int64 =
struct

  type int = Int64.int
  val toInt = Int64.toInt32
  val fromInt = Int64.fromInt32

  val precision = SOME 64
  val minInt = SOME ~0x8000000000000000
  val maxInt = SOME 0x7fffffffffffffff

  val toLarge = 
      _import "prim_IntInf_fromInt64"
      : __attribute__((unsafe,pure,fast,gc)) int -> IntInf.int

  val prim_fromLarge =
      _import "prim_IntInf_toInt64"
      : __attribute__((pure,fast)) IntInf.int -> int

  fun fromLarge x =
      if IntInf.< (x, toLarge (Option.valOf minInt)) orelse 
         IntInf.< (toLarge (Option.valOf maxInt), x)
      then raise Overflow
      else prim_fromLarge x

  val op + = Int64.add_unsafe
  val op - = Int64.sub_unsafe
  val op * = Int64.mul_unsafe
  val op div = Int64.div
  val op mod = Int64.mod
  val quot = Int64.quot
  val rem = Int64.rem
  val op < = Int64.lt
  val op <= = Int64.lteq
  val op > = Int64.gt
  val op >= = Int64.gteq
  val ~ = Int64.neg
  val abs = Int64.abs

  fun compare (left, right) =
      if left < right then General.LESS
      else if left = right then General.EQUAL
      else General.GREATER
  fun min (left, right) = if left < right then left else right
  fun max (left, right) = if left > right then left else right
  fun sign num = if num < 0 then ~1 else if num = 0 then 0 else 1
  fun sameSign (left, right) = (sign left) = (sign right)

  fun fmt radix n =
      let
        val r = fromInt (SMLSharp_ScanChar.radixToInt radix)
        (* use nagative to avoid Overflow *)
        fun loop (n, z) =
            if n >= 0 then z
            else let val q = Int64.quot_unsafe (n, r)
                     val r = Int64.rem_unsafe (n, r)
                 in loop (q, SMLSharp_ScanChar.intToDigit (toInt (~r)) :: z)
                 end
      in
        if n = 0 then "0"
        else if n > 0 then String.implode (loop (~n, nil))
        else String.implode (#"~" :: loop (n, nil))
      end

  fun scan radix (getc : (char, 'a) StringCvt.reader) strm =
      case SMLSharp_ScanChar.scanInt radix getc strm of
        NONE => NONE
      | SOME ({neg, radix=r, digits}, strm) =>
        let
          val digits = List.map fromInt digits
          val r = fromInt r
          fun posloop (z, nil) = SOME (z, strm)
            | posloop (z, h::t) =
              (* raise Overflow if z * r + h >= 0x8000000000000000 *)
              if (case radix of
                    StringCvt.BIN => z >= 0x4000000000000000
                  | StringCvt.OCT => z >= 0x1000000000000000
                  | StringCvt.DEC => z >= 0x0ccccccccccccccd - 
                                          (if h > 7 then 1 else 0)
                  | StringCvt.HEX => z >= 0x0800000000000000)
              then raise Overflow
              else posloop (z * r + h, t)
          fun negloop (z, nil) = SOME (z, strm)
            | negloop (z, h::t) =
              (* raise Overflow if z * r + h < ~0x8000000000000000 *)
              if (case radix of
                    StringCvt.BIN => z <= ~0x4000000000000001 + 
                                          (if h > 0 then 1 else 0)
                  | StringCvt.OCT => z <= ~0x1000000000000001 + 
                                          (if h > 0 then 1 else 0)
                  | StringCvt.DEC => z <= ~0x0ccccccccccccccd + 
                                          (if h > 8 then 1 else 0)
                  | StringCvt.HEX => z <= ~0x0800000000000001 + 
                                          (if h > 0 then 1 else 0)
                 )
              then raise Overflow
              else negloop (z * r - h, t)
        in
          if neg then negloop (0, digits) else posloop (0, digits)
        end

  fun toString n =
      fmt StringCvt.DEC n

  fun fromString s =
      StringCvt.scanString (scan StringCvt.DEC) s

end
