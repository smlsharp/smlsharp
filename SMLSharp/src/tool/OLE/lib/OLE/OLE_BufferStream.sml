(**
 * abstraction of accessors on Word8Array and UnmanagedMemory.
 * @copyright (c) 2010, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: OLE.sml,v 1.27.22.2 2010/05/09 03:58:29 kiyoshiy Exp $
 *)
structure OLE_BufferStream : OLE_BUFFER_STREAM =
struct

  structure UM = UnmanagedMemory
  structure BA = Word8Array
  structure DC = OLE_DataConverter

  type instream = {input : int -> (Word8.word * int), offset : int}
  type outstream = {output : (int * Word8.word) -> int, offset : int}

  fun openArrayIn array =
      let
        fun input offset = (BA.sub (array, offset), offset + 1)
        val offset = 0
      in {input = input, offset = offset} end
  fun openUnmanagedMemoryIn (address, size)=
      let
        fun input offset =
            if offset < 0 orelse size <= offset
            then raise General.Subscript
            else (UM.sub (UM.advance(address, offset)), offset + 1)
        val offset = 0
      in {input = input, offset = offset} end
  fun openArrayOut array =
      let
        fun output (offset, byte) =
            (BA.update (array, offset, byte); offset + 1)
        val offset = 0
      in {output = output, offset = offset} end
  fun openUnmanagedMemoryOut (address, size) =
      let
        fun output (offset, byte) =
            if offset < 0 orelse size <= offset
            then raise General.Subscript
            else (UM.update (UM.advance(address, offset), byte); offset + 1)
        val offset = 0
      in {output = output, offset = offset} end
  fun input {input, offset} =
      let val (byte, offset) = input offset
      in (byte, {input = input, offset = offset}) end
  fun inputWord32 {input, offset} =
      let
        val (byte1, offset) = input offset
        val (byte2, offset) = input offset
        val (byte3, offset) = input offset
        val (byte4, offset) = input offset
        val word32 = DC.word8QuadToWord32 (byte1, byte2, byte3, byte4)
      in
        (word32, {input = input, offset = offset})
      end
  fun output ({output, offset}, byte) =
      let val offset = output (offset, byte)
      in {output = output, offset = offset} end
  fun outputWord32 ({output, offset}, word32) =
      let
        val (byte1, byte2, byte3, byte4) = DC.word32ToWord8Quad word32
        val offset = output (offset, byte1)
        val offset = output (offset, byte2)
        val offset = output (offset, byte3)
        val offset = output (offset, byte4)
      in
        {output = output, offset = offset}
      end
  fun skipIn ({input, offset}, length) =
      {input = input, offset = offset + length}
  fun skipOut ({output, offset}, length) =
      {output = output, offset = offset + length}
  fun getPosIn {input, offset} = offset
  fun getPosOut {output, offset} = offset

end;