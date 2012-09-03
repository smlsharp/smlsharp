(**
 * Byte structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Byte.sml,v 1.2 2005/12/12 14:54:23 kiyoshiy Exp $
 *)
structure Byte :> BYTE =
struct

  (***************************************************************************)

  fun byteToChar (word : Word8.word) = _cast (word) : char

  fun charToByte (char : char) = _cast (char) : Word8.word

  fun bytesToString (vector : Word8Vector.vector) =
      _cast (vector) : string
  fun stringToBytes (string : string) =
      _cast (string) : Word8Vector.vector

  fun unpackStringVec (vectorSlice : Word8VectorSlice.slice) =
      _cast (Word8VectorSlice.vector vectorSlice) : string

  fun unpackString (arraySlice : Word8ArraySlice.slice) =
      _cast (Word8ArraySlice.vector arraySlice) : string

  fun packString (array, start, substring) =
      let
        val substringSize = Substring.size substring
      in
        if (start < 0) orelse Word8Array.length array < (substringSize + start)
        then raise Subscript
        else
          let
            val arraySlice = 
                Word8ArraySlice.slice (array, start, SOME substringSize)
          in
            Word8ArraySlice.modifyi
                (fn (index, _) => charToByte(Substring.sub (substring, index)))
                arraySlice
          end
      end

  (***************************************************************************)

end;