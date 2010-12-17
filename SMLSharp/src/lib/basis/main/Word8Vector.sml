(**
 * Word8Vector structure.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: Word8Vector.sml,v 1.6 2007/12/19 02:00:56 kiyoshiy Exp $
 *)
local
  (* ToDo : use primitives for bytearray. *)
  structure Operations =
  struct
    type elem = Word8.word
    type vector = CharVector.vector
    val maxLen = CharVector.maxLen
    val makeVector =
        fn (size, initial) =>
           SMLSharp.PrimString.vector (size, Char.chr(Word8.toInt initial))
    val makeEmptyVector = fn () => CharVector.fromList []
    val length = CharVector.length
    val update =
        fn (vector, index, byte) =>
           CharArray.update (vector, index, Char.chr(Word8.toInt byte))
    val copy = CharVector.copy
    val sub =
        fn (vector, index) =>
           Word8.fromInt(Char.ord(CharVector.sub (vector, index)))
  end
in
structure Word8Vector = MonoVectorBase(Operations)
end
