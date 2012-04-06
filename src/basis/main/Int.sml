(**
 * Integer related structures.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 *
 * @author Atsushi Ohori (refactored from IntStructure)
 * @copyright 2010, 2011, Tohoku University.
*)

(*
  2012-1-6 Ohori:
  I rewote this from IntStructre.
  This is of of the fundamental structures that must to be defined directly.
*)

_interface "Int.smi"

structure Int : sig
  type int = SMLSharp.Int.int
  val toLarge : int -> IntInf.int
  val fromLarge : IntInf.int -> int
  val toInt : int -> SMLSharp.Int.int
  val fromInt : SMLSharp.Int.int -> int
  val precision : SMLSharp.Int.int option
  val minInt : int option
  val maxInt : int option
  val + : int * int -> int
  val - : int * int -> int
  val * : int * int -> int
  val div : int * int -> int
  val mod : int * int -> int
  val quot : int * int -> int
  val rem : int * int -> int
  val compare : int * int -> order
  val < : int * int -> bool
  val <= : int * int -> bool
  val > : int * int -> bool
  val >= : int * int -> bool
  val ~ : int -> int
  val abs : int -> int
  val min : int * int -> int
  val max : int * int -> int
  val sign : int -> SMLSharp.Int.int
  val sameSign : int * int -> bool
  val fmt : StringCvt.radix -> int -> string
  val toString : int -> string
  val scan : StringCvt.radix
             -> (char, 'a) StringCvt.reader
             -> (int, 'a) StringCvt.reader
  val fromString : string -> int option
  end =
struct
local
  infix 7 * / div mod
  infix 6 + -
  infixr 5 ::
  infix 4 = <> > >= < <=
in
  type int = int
  fun toInt x = x : int
  fun fromInt x = x : int
  val toLarge = LargeInt.fromInt
  val fromLarge = LargeInt.toInt

  val precision = SOME 32
  val minInt = SOME ~0x80000000
  val maxInt = SOME 0x7fffffff

  val op + = SMLSharp.Int.add
  val op - = SMLSharp.Int.sub
  val op * = SMLSharp.Int.mul
  val op div = SMLSharp.Int.div
  val op mod = SMLSharp.Int.mod
  val op quot = SMLSharp.Int.quot
  val op rem = SMLSharp.Int.rem
  val op < = SMLSharp.Int.lt
  val op > = SMLSharp.Int.gt
  val op <= = SMLSharp.Int.lteq
  val op >= = SMLSharp.Int.gteq
  val ~ = SMLSharp.Int.neg
  val abs = SMLSharp.Int.abs

  fun compare (left, right) =
      if left < right then LESS else if left = right then EQUAL else GREATER
  fun min (left, right) = if left < right then left else right
  fun max (left, right) = if left > right then left else right
  fun sign num = if num < 0 then ~1 else if num = 0 then 0 else 1
  fun sameSign (left, right) = (sign left) = (sign right)

  fun fmt radix n =
      let
        val r = SMLSharpScanChar.radixToInt radix
        (* use nagative to avoid Overflow *)
        fun loop (n, z) =
            if n >= 0 then z
            else let val (n, m) = (quot (n, r), ~(rem (n, r)))
                 in loop (n, SMLSharpScanChar.intToDigit m :: z)
                 end
      in
        if n = 0 then "0"
        else if n > 0 then implode (loop (~n, nil))
        else implode (#"~" :: loop (n, nil))
      end

  fun scan radix getc strm =
      case SMLSharpScanChar.scanInt radix getc strm of
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
end

structure Position = Int
structure Int32 = Int
