(**
 * common implementation of Word structures
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

(*
 * This file is included in Word<N>.sml by "_use" for each <N>.
 * Before "_use" this file, the following Int structure must be defined.

structure Word =
struct
  open SMLSharp_Builtin.Word64
  type word = word64
  val wordSize = 64
  val fromWord32X = SMLSharp_Builtin.Word32.toWord64
  val fromLarge = SMLSharp_Builtin.Word64.toWord64
  val toLargeInt = ...
  fun toLargeIntX x = ...
  val fromLargeInt = ...
end

*)

infix 7 * / div mod
infix 6 + -
infixr 5 ::
infix 4 = <> > >= < <=

structure Word_common =
struct

  type word = Word.word

  val wordSize = Word.wordSize

  val toLarge = Word.toWord64
  val toLargeX = Word.toWord64X
  val toLargeWord = toLarge
  val toLargeWordX = toLargeX
  val fromLarge = Word.fromLarge
  val fromLargeWord = fromLarge

  val toLargeInt = Word.toLargeInt
  val toLargeIntX = Word.toLargeIntX
  val fromLargeInt = Word.fromLargeInt

  val toInt = Word.toInt32
  val toIntX = Word.toInt32X
  val fromInt = Word.fromInt32
  val andb = Word.andb
  val orb = Word.orb
  val xorb = Word.xorb
  val notb = Word.notb
  val << = Word.lshift
  val >> = Word.rshift
  val ~>> = Word.arshift
  val op + = Word.add
  val op - = Word.sub
  val op * = Word.mul
  val op div = Word.div
  val op mod = Word.mod
  val op < = Word.lt
  val op <= = Word.lteq
  val op > = Word.gt
  val op >= = Word.gteq
  val ~ = Word.neg

  fun compare (x, y) =
      if x = y then General.EQUAL
      else if x < y then General.LESS
      else General.GREATER

  fun min (x, y) = if x < y then x else y
  fun max (x, y) = if x > y then x else y

  fun fromInt32_fast x =
      Word.fromWord32X (SMLSharp_Builtin.Word32.fromInt32 x)
  fun toInt32_fast x =
      SMLSharp_Builtin.Word32.toInt32X (Word.toWord32 x)

  fun fmt radix n =
      let
        val r = fromInt32_fast (SMLSharp_ScanChar.radixToInt radix)
        fun loop (n, z) =
            if n = 0w0 then String.implode z
            else let val q = n div r
                     val r = toInt32_fast (n mod r)
                 in loop (q, SMLSharp_ScanChar.intToDigit r :: z)
                 end
      in
        if n = 0w0 then "0" else loop (n, nil)
      end

  fun scan radix (getc : (char, 'a) StringCvt.reader) strm =
      case SMLSharp_ScanChar.scanWord radix getc strm of
        NONE => NONE
      | SOME ({radix=r, digits}, strm) =>
        let
          val r = fromInt32_fast r
          val max = fromInt32_fast ~1 div r
          fun loop z nil = SOME (z, strm)
            | loop z (h::t) =
              let
                val h = fromInt32_fast h
                val a = if z <= max then z * r else raise Overflow
                val b = a + h
                val _ = if b >= a then () else raise Overflow
              in
                loop b t
              end
        in
          loop 0w0 digits
        end

  fun toString w =
      fmt StringCvt.HEX w

  fun fromString s =
      StringCvt.scanString (scan StringCvt.HEX) s

end
