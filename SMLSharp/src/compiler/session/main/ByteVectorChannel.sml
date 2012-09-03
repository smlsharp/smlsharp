(**
 * implementation of channel on a byte array.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ByteVectorChannel.sml,v 1.8 2007/12/04 06:35:46 kiyoshiy Exp $
 *)
structure ByteVectorChannel =
struct

  (***************************************************************************)

  structure CU = ChannelUtility
  structure V = Word8Vector
  structure VS = Word8VectorSlice
  structure A = Word8Array
  structure AS = Word8ArraySlice

  (***************************************************************************)

  type InitialInputParameter =
       {
         buffer : V.vector
       }

  (***************************************************************************)

  fun openSliceIn {buffer, start, lenOpt} =
      let
        val bufferLength = V.length buffer
        val next =
            if 0 <= start andalso start <= bufferLength
            then ref start
            else raise General.Subscript
        (* index next to the last element. *)
        val last = 
            case lenOpt
             of NONE => bufferLength
              | SOME len =>
                if start + len <= bufferLength
                then start + len
                else raise General.Subscript
        fun receive () =
            if !next < last
            then (SOME (V.sub (buffer, !next)) before next := !next + 1)
            else NONE
        fun receiveArray required =
            let
              val available = last - (!next)
              val returnSize =
                  if available <= required then available else required
              val returnArray = A.array (returnSize, 0w0)
              val _ =
                  AS.copyVec
                  {
                    src = VS.slice (buffer,!next,SOME returnSize),
                    (*si = !next,
                    len = SOME returnSize,*)
                    dst = returnArray,
                    di = 0
                  }
              val _ = next := (!next) + returnSize
            in
              returnArray
            end
        fun receiveVector required =
            let
              val available = last - (!next)
              val returnSize =
                  if available <= required then available else required
              val returnVector =
                  VS.vector (VS.slice (buffer, !next, SOME returnSize))
              val _ = next := (!next) + returnSize
            in
              returnVector
            end
        val getLine = CU.mkGetLine receive
        fun getPos () = Word32.fromInt (!next)
        fun seek (pos, offset) =
            let
              val newPos = Word32.toIntX pos + offset
            in
              if 0 <= newPos andalso newPos <= last
              then next := newPos
              else raise Fail ("seek:pos=" ^ Int.toString(Word32.toIntX pos) ^ ",offset=" ^ Int.toString offset)
            end
        fun close () = ()
        fun isEOF () = (!next) = last
      in
        {
          receive = receive,
          receiveArray = receiveArray,
          receiveVector = receiveVector,
          getLine = getLine,
          getPos = SOME getPos,
          seek = SOME seek,
          close = close,
          isEOF = isEOF
        } : ChannelTypes.InputChannel
      end

  fun openIn {buffer} = openSliceIn {buffer = buffer, start = 0, lenOpt = NONE}

  (***************************************************************************)

end
