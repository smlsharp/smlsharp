(**
 * implementation of channel on a byte array.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ByteArrayChannel.sml,v 1.4 2006/02/28 16:11:04 kiyoshiy Exp $
 *)
structure ByteArrayChannel =
struct

  (***************************************************************************)

  type InitialOutputParameter =
       {
         buffer : Word8Array.array option ref
       }

  type InitialInputParameter =
       {
         buffer : Word8Array.array
       }

  (***************************************************************************)

  fun openOut {buffer} =
      let
        val bufferListRef = ref ([] : Word8.word list)
        fun send word = bufferListRef := (word :: (!bufferListRef))
        fun sendArray array =
            Word8Array.foldl
            (fn (word, ()) => bufferListRef := (word :: (!bufferListRef)))
            ()
            array
        fun flush () = ()
        fun close () =
            buffer := SOME(Word8Array.fromList(rev (!bufferListRef)))
      in
        {
          send = send,
          sendArray = sendArray,
          flush = flush,
          close = close
        } : ChannelTypes.OutputChannel
      end

  fun openIn {buffer} =
      let
        val bufferSize = Word8Array.length buffer
        val next = ref 0
        fun receive () =
            if bufferSize = (!next)
            then NONE
            else SOME (Word8Array.sub (buffer, !next)) before next := !next + 1
        fun receiveArray required =
            let
              val available = bufferSize - (!next)
              val returnSize =
                  if available <= required then available else required
              val returnArray = Word8Array.array (returnSize, 0w0)
              val _ =
                  Word8Array.copy
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
