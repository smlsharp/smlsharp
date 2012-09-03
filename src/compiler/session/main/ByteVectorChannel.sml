(**
 * implementation of channel on a byte array.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ByteVectorChannel.sml,v 1.1 2006/01/13 15:05:33 kiyoshiy Exp $
 *)
structure ByteVectorChannel =
struct

  (***************************************************************************)

  type InitialInputParameter =
       {
         buffer : Word8Vector.vector
       }

  (***************************************************************************)

  fun openIn {buffer} =
      let
        val bufferSize = Word8Vector.length buffer
        val next = ref 0
        fun receive () =
            if bufferSize = (!next)
            then NONE
            else
              SOME (Word8Vector.sub (buffer, !next)) before next := !next + 1
        fun receiveArray required =
            let
              val available = bufferSize - (!next)
              val returnSize =
                  if available <= required then available else required
              val returnArray = Word8Array.array (returnSize, 0w0)
              val _ =
                  Word8Array.copyVec
                  {
                    src = buffer,
                    si = !next,
                    len = SOME returnSize,
                    dst = returnArray,
                    di = 0
                  }
              val _ = next := (!next) + returnSize
            in
              returnArray
            end
        fun close () = ()
        fun isEOF () = (!next) = bufferSize
      in
        {
          receive = receive,
          receiveArray = receiveArray,
          close = close,
          isEOF = isEOF
        } : ChannelTypes.InputChannel
      end          

  (***************************************************************************)

end
