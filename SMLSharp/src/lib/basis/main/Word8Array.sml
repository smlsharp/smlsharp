(**
 * Word8Array structure.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: Word8Array.sml,v 1.5 2007/12/19 02:00:56 kiyoshiy Exp $
 *)
local
  (* ToDo : use primitives for bytearray. *)
  structure Operations =
  struct
    type elem = Word8.word
    type array = CharArray.array
    val maxLen = CharArray.maxLen
    val makeMutableArray =
        fn (size, initial) =>
           CharArray.array (size, Char.chr(Word8.toInt initial))
    val makeEmptyMutableArray = fn () => CharArray.fromList []
    val makeImmutableArray =
        fn (size, initial) =>
           CharArray.array (size, Char.chr(Word8.toInt initial))
    val makeEmptyImmutableArray = fn () => CharArray.fromList []
    val length = CharArray.length
    val update =
        fn (vector, index, byte) =>
           CharArray.update (vector, index, Char.chr(Word8.toInt byte))
    val copy = CharArray.copySlice
    val sub =
        fn (vector, index) =>
           Word8.fromInt(Char.ord(CharArray.sub (vector, index)))
  end
in
structure Word8Array = MonoArrayBase(Operations)
end;
