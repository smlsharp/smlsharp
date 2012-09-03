(**
 * Integer related structures.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 *
 * @author Atsushi Ohori
 * @copyright 2010, 2011, Tohoku University.
 *)
_interface "Word8.smi"

structure Word8 : sig
    (* same as WORD *)
    type word = SMLSharp.Word8.word
    val wordSize : int
    val toLarge : word -> LargeWord.word
    val toLargeX : word -> LargeWord.word
    val toLargeWord : word -> LargeWord.word
    val toLargeWordX : word -> LargeWord.word
    val fromLarge : LargeWord.word -> word
    val fromLargeWord : LargeWord.word -> word
    val toLargeInt : word -> IntInf.int
    val toLargeIntX : word -> IntInf.int
    val fromLargeInt : IntInf.int -> word
    val toInt : word -> int
    val toIntX : word -> int
    val fromInt : int -> word
    val andb : word * word -> word
    val orb : word * word -> word
    val xorb : word * word -> word
    val notb : word -> word
    val << : word * SMLSharp.Word.word -> word
    val >> : word * SMLSharp.Word.word -> word
    val ~>> : word * SMLSharp.Word.word -> word
    val + : word * word -> word
    val - : word * word -> word
    val * : word * word -> word
    val div : word * word -> word
    val mod : word * word -> word
    val compare : word * word -> order
    val < : word * word -> bool
    val <= : word * word -> bool
    val > : word * word -> bool
    val >= : word * word -> bool
    val ~ : word -> word
    val min : word * word -> word
    val max : word * word -> word
    val fmt : StringCvt.radix -> word -> string
    val toString : word -> string
    val scan : StringCvt.radix
               -> (char, 'a) StringCvt.reader
               -> (word, 'a) StringCvt.reader
    val fromString : string -> word option
  end =
struct
local
  infix 7 * / div mod
  infix 6 + -
  infixr 5 ::
  infix 4 = <> > >= < <=
in
  type word = SMLSharp.Word8.word
  val wordSize = 8  (* 8-bit unsigned integer *)
  val toInt = SMLSharp.Word8.toInt
  val toIntX = SMLSharp.Word8.toIntX
  val toLarge = SMLSharp.Word8.toWord
  val toLargeWord = SMLSharp.Word8.toWord
  val fromInt = SMLSharp.Word8.fromInt
  val fromLarge = SMLSharp.Word8.fromWord
  val fromLargeWord = SMLSharp.Word8.fromWord
  val op + = SMLSharp.Word8.add
  val op - = SMLSharp.Word8.sub
  val op * = SMLSharp.Word8.mul
  val op div = SMLSharp.Word8.div
  val op mod = SMLSharp.Word8.mod
  val op < = SMLSharp.Word8.lt
  val op <= = SMLSharp.Word8.lteq
  val op > = SMLSharp.Word8.gt
  val op >= = SMLSharp.Word8.gteq

  fun toLargeX x = SMLSharp.Word.fromInt (SMLSharp.Word8.toIntX x)
  val toLargeWordX = toLargeX
  fun toLargeInt x = IntInf.fromWord (SMLSharp.Word8.toWord x)
  fun toLargeIntX x = IntInf.fromInt (SMLSharp.Word8.toIntX x)
  fun fromLargeInt x = SMLSharp.Word8.fromWord (IntInf.toWord x)
  (* ToDo: the following should be builtin primitives *)
  fun andb (x, y) = fromLarge (SMLSharp.Word.andb (toLarge x, toLarge y))
  fun orb (x, y) = fromLarge (SMLSharp.Word.orb (toLarge x, toLarge y))
  fun xorb (x, y) = fromLarge (SMLSharp.Word.xorb (toLarge x, toLarge y))
  fun notb x = fromLarge (SMLSharp.Word.notb (toLarge x))
  fun << (x, y) = fromLarge (SMLSharp.Word.lshift (toLarge x, y))
  fun >> (x, y) = fromLarge (SMLSharp.Word.rshift (toLarge x, y))
  fun ~>> (x, y) = fromLarge (SMLSharp.Word.arshift (toLarge x, y))
  fun op ~ x = fromLarge (SMLSharp.Word.neg (toLarge x))
  fun compare (x, y) =
      if x = y then EQUAL else if x < y then LESS else GREATER

  fun min (x, y) = if x < y then x else y
  fun max (x, y) = if x > y then x else y

  fun fmt radix n =
      LargeWord.fmt radix (toLarge n)

  fun scan radix getc strm =
      case LargeWord.scan radix getc strm of
        NONE => NONE
      | SOME (x, strm) =>
        if SMLSharp.Word.gt (x, 0wxff) then raise Overflow
        else SOME (SMLSharp.Word8.fromWord x, strm)

  fun toString n =
      fmt StringCvt.HEX n

  fun fromString s =
      StringCvt.scanString (scan StringCvt.HEX) s

end
end
