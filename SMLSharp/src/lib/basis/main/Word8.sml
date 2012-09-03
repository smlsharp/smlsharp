(**
 * Word8 structure.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: Word8.sml,v 1.6 2007/08/09 02:38:20 kiyoshiy Exp $
 *)
structure Word8 =
struct
  open Word8

  (***************************************************************************)

  val wordSize = 8

(*
  fun Word8_toWord (byte : byte) = _cast (byte) : Word.word
  fun Word8_fromWord (word : Word.word) = _cast (Word.andb(word, 0wxFF)) : byte
*)
  (* ToDo : We should have toInt and toIntX both. *)
  fun Word8_toWord x = 
      Word.fromInt (let val n = toIntX x in if n < 0 then n + 256 else n end)
  fun Word8_toWordX x = Word.fromInt (toIntX x)
  fun Word8_fromWord x = fromInt (Word.toIntX x)

  fun toLarge x = Word.toLargeWord (Word8_toWord x)
  fun toLargeX x = Word.toLargeWordX (Word8_toWordX x)
  fun fromLarge x = Word8_fromWord (Word.fromLargeWord x)

  val toLargeWord = toLarge
  val toLargeWordX = toLargeX
  val fromLargeWord = fromLarge

  fun toLargeInt x = Word.toLargeInt (Word8_toWord x)
  fun toLargeIntX x = Word.toLargeIntX (Word8_toWordX x)
  fun fromLargeInt x = Word8_fromWord (Word.fromLargeInt x)

  fun toInt x = let val n = toIntX x in if n < 0 then 256 + n else n end
  val toIntX = toIntX
  val fromInt = fromInt

  fun cast1_1 f word1 = Word8_fromWord(f (Word8_toWord word1))
  fun cast2 f (word1, word2) = f (Word8_toWord word1, Word8_toWord word2)
  fun cast2_1 f (word1, word2) =
      Word8_fromWord(f (Word8_toWord word1, Word8_toWord word2))
  fun cast10_1 f (word1, word2) =
      Word8_fromWord(f (Word8_toWord word1, word2))

  fun orb x = cast2_1 Word.orb x

  fun xorb x = cast2_1 Word.xorb x

  fun andb x = cast2_1 Word.andb x

  fun notb x = cast1_1 Word.notb x

  fun << x = cast10_1 Word.<< x

  fun >> x = cast10_1 Word.>> x

  val ~>> = fn (b, w) => Word8_fromWord (Word.~>> (Word8_toWordX b, w))

  val ~ = fn word => fromInt(Int.~(toInt word))

  fun op + x = cast2_1 Word.+ x

  fun op - x = cast2_1 Word.- x

  fun op * x = cast2_1 Word.* x

  fun op div x = cast2_1 Word.div x

  fun op mod x = cast2_1 Word.mod x

  fun compare x = cast2 Word.compare x

  fun op > x = cast2 Word.> x
  fun op < x = cast2 Word.< x
  fun op >= x = cast2 Word.>= x
  fun op <= x = cast2 Word.<= x

  fun min x = cast2_1 Word.min x
  fun max x = cast2_1 Word.max x

  fun fmt radix word8 = Word.fmt radix (Word8_toWord word8)

  fun toString x = Word.toString (Word8_toWord x)

  fun fromString string = Option.map Word8_fromWord (Word.fromString string)

  fun castReader wordReader =
      fn stream =>
         case wordReader stream of
           NONE => NONE
         | SOME(word, stream') =>
           if Word.< (0wxFF, word)
           then raise Overflow
           else SOME(Word8_fromWord word, stream')
  fun scan radix charReader = castReader(Word.scan radix charReader)

  (***************************************************************************)

end