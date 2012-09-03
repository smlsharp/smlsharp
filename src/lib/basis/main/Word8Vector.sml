(**
 * Word8Vector structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Word8Vector.sml,v 1.4 2006/02/20 01:41:12 kiyoshiy Exp $
 *)
local
  structure Operations =
  struct
    type elem = byte
    type array = CharArray.array
    val maxLen = CharArray.maxLen
    val makeArray =
        fn (size, initial) =>
           CharArray.array (size, Char.chr(Word8.toInt initial))
    val length = CharArray.length
    val update =
        fn (array, index, byte) =>
           CharArray.update (array, index, Char.chr(Word8.toInt byte))
    val sub =
        fn (array, index) =>
           Word8.fromInt(Char.ord(CharArray.sub (array, index)))
    val emptyArray = fn () => CharArray.fromList []
  end
in
structure Word8Vector = MonoVectorBase(Operations)
end;
