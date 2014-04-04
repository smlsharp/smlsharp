(**
 * Int, Int32, Position
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

(* NOTE: Int assumes that integer is 32 bit *)

infix 7 * / div mod
infix 6 + -
infixr 5 ::
infix 4 = <> > >= < <=
structure Int = SMLSharp_Builtin.Int

structure Int =
struct

  type int = int
  fun toInt x = x : int
  fun fromInt x = x : int

  val precision = SOME 32
  val minInt = SOME ~0x80000000
  val maxInt = SOME 0x7fffffff

  val toLarge = LargeInt.fromInt
  val fromLarge = LargeInt.toInt
  val op + = Int.add_unsafe
  val op - = Int.sub_unsafe
  val op * = Int.mul_unsafe
  val op div = Int.div
  val op mod = Int.mod
  val quot = Int.quot
  val rem = Int.rem
  val op < = Int.lt
  val op <= = Int.lteq
  val op > = Int.gt
  val op >= = Int.gteq
  val ~ = Int.neg
  val abs = Int.abs

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
        val r = SMLSharp_ScanChar.radixToInt radix
        (* use nagative to avoid Overflow *)
        fun loop (n, z) =
            if n >= 0 then z
            else let val q = Int.quot_unsafe (n, r)
                     val r = Int.rem_unsafe (n, r)
                 in loop (q, SMLSharp_ScanChar.intToDigit (~r) :: z)
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
          fun posloop (z, nil) = SOME (z, strm)
            | posloop (z, h::t) =
              (* raise Overflow if z * r + h >= 0x80000000 *)
              if (case radix of
                    StringCvt.BIN => z >= 0x40000000
                  | StringCvt.OCT => z >= 0x10000000
                  | StringCvt.DEC => z >= 0x0ccccccd - (if h > 7 then 1 else 0)
                  | StringCvt.HEX => z >= 0x08000000)
              then raise Overflow
              else posloop (z * r + h, t)
          fun negloop (z, nil) = SOME (z, strm)
            | negloop (z, h::t) =
              (* raise Overflow if z * r + h < ~0x80000000 *)
              if (case radix of
                    StringCvt.BIN => z <= ~0x40000001 + (if h > 0 then 1 else 0)
                  | StringCvt.OCT => z <= ~0x10000001 + (if h > 0 then 1 else 0)
                  | StringCvt.DEC => z <= ~0x0ccccccd + (if h > 8 then 1 else 0)
                  | StringCvt.HEX => z <= ~0x08000001 + (if h > 0 then 1 else 0)
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

structure Position = Int
structure Int32 = Int
