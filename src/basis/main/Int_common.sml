(**
 * common implementation of Int structures
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

(*
 * This file is included in Int<N>.sml by "_use" for each <N>.
 * Before "_use" this file, the following Int structure must be defined.

structure Int =
struct
  open SMLSharp_Builtin.Int64
  type int = int64
  val precision = 64
  val minInt = ~0x8000000000000000 : int
  val maxInt = 0x7fffffffffffffff : int
  val Word32_toWordN = SMLSharp_Builtin.Word32.toWord64
  val WordN_toIntNX = SMLSharp_Builtin.Word64.toInt64X
  val toLarge = ...
  val fromLarge = ...
end

*)

infix 7 * / div mod
infix 6 + -
infixr 5 ::
infix 4 = <> > >= < <=

structure Int_common =
struct
  type int = Int.int
  val precision = SOME Int.precision
  val minInt = SOME Int.minInt
  val maxInt = SOME Int.maxInt
  val toInt = Int.toInt32
  val fromInt = Int.fromInt32
  val toLarge = Int.toLarge
  val fromLarge = Int.fromLarge

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

  fun fromInt32_fast x =
      Int.WordN_toIntNX
        (Int.Word32_toWordN (SMLSharp_Builtin.Word32.fromInt32 x))

  fun fmt radix n =
      let
        val r = fromInt32_fast (SMLSharp_ScanChar.radixToInt radix)
        (* use nagative to avoid Overflow *)
        fun loop (n, z) =
            if n >= 0 then z
            else let val q = Int.quot_unsafe (n, r)
                     val r = Int.rem_unsafe (n, r)
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
          val op + = Int.add
          val op - = Int.sub
          val op * = Int.mul
          val r = fromInt32_fast r
          fun posloop z nil = SOME (z, strm)
            | posloop z (h::t) = posloop (z * r + fromInt32_fast h) t
          fun negloop z nil = SOME (z, strm)
            | negloop z (h::t) = negloop (z * r - fromInt32_fast h) t
        in
          if neg then negloop 0 digits else posloop 0 digits
        end

  fun toString n =
      fmt StringCvt.DEC n

  fun fromString s =
      StringCvt.scanString (scan StringCvt.DEC) s

end
