(**
 * Word8 structure.
 * @author YAMATODANI Kiyoshi
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
  fun Word8_toWord x = Word.fromInt (toIntX x)
  fun Word8_fromWord x = fromInt (Word.toIntX x)

  val toLarge = Word.toLargeWord o Word8_toWord
  val toLargeX = Word.toLargeWordX o Word8_toWord
  val fromLarge = Word8_fromWord o Word.fromLargeWord

  val toLargeWord = toLarge
  val toLargeWordX = toLargeX
  val fromLargeWord = fromLarge

  val toLargeInt = Word.toLargeInt o Word8_toWord
  val toLargeIntX = Word.toLargeIntX o Word8_toWord
  val fromLargeInt = Word8_fromWord o Word.fromLargeInt

  val toInt = Word.toInt o Word8_toWord
  val toIntX = Word.toIntX o Word8_toWord
  val fromInt = Word8_fromWord o Word.fromInt

  fun cast1_1 f word1 = Word8_fromWord(f (Word8_toWord word1));
  fun cast2 f (word1, word2) = f (Word8_toWord word1, Word8_toWord word2);
  fun cast2_1 f (word1, word2) =
      Word8_fromWord(f (Word8_toWord word1, Word8_toWord word2));
  fun cast10_1 f (word1, word2) =
      Word8_fromWord(f (Word8_toWord word1, word2));

  val orb = cast2_1 Word.orb

  val xorb = cast2_1 Word.xorb

  val andb = cast2_1 Word.andb

  val notb = cast1_1 Word.notb

  val << = cast10_1 Word.<<

  val >> = cast10_1 Word.>>

  val ~>> = cast10_1 Word.~>>

  val ~ = fn word => fromInt(Int.~(toInt word))

  val op + = cast2_1 Word.+

  val op - = cast2_1 Word.-

  val op * = cast2_1 Word.*

  val op div = cast2_1 Word.div

  val op mod = cast2_1 Word.mod

  val compare = cast2 Word.compare

  val op > = cast2 Word.>
  val op < = cast2 Word.<
  val op >= = cast2 Word.>=
  val op <=  = cast2 Word.<=

  val min = cast2_1 Word.min
  val max = cast2_1 Word.max

  fun fmt radix word8 = Word.fmt radix (Word8_toWord word8)

  val toString = Word.toString o Word8_toWord

  fun fromString string = Option.map Word8_fromWord (Word.fromString string)

  fun castReader wordReader =
      fn stream =>
         case wordReader stream of
           NONE => NONE
         | SOME(word, stream') => SOME(Word8_fromWord word, stream')
  fun scan radix charReader = castReader(Word.scan radix charReader)

  (***************************************************************************)

end;