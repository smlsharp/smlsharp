(**
 * implementation of channel on a byte array.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ByteArrayChannel.sml,v 1.6 2007/05/01 02:21:26 kiyoshiy Exp $
 *)
structure ByteArrayChannel =
struct

  (***************************************************************************)

  structure V = Word8Vector
  structure A = Word8Array

  (***************************************************************************)

  type InitialOutputParameter =
       {
         buffer : A.array option ref
       }

  type InitialInputParameter =
       {
         buffer : A.array
       }

  (***************************************************************************)

  fun openOut {buffer} =
      let
        val bufferListRef = ref ([] : Word8.word list)
        fun send word = bufferListRef := (word :: (!bufferListRef))
        fun sendArray array =
            A.foldl
                (fn (word, ()) => bufferListRef := (word :: (!bufferListRef)))
                ()
                array
        fun sendVector vector=
            V.foldl
                (fn (word, ()) => bufferListRef := (word :: (!bufferListRef)))
                ()
                vector
        fun flush () = ()
        fun close () =
            buffer := SOME(A.fromList(rev (!bufferListRef)))
      in
        {
          send = send,
          sendArray = sendArray,
          sendVector = sendVector,
          flush = flush,
          close = close
        } : ChannelTypes.OutputChannel
      end

  fun openSliceIn {buffer, start, lenOpt} =
      let
        val bufferLength = A.length buffer
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
            then SOME (A.sub (buffer, !next)) before next := !next + 1
            else NONE
        fun receiveArray required =
            let
              val available = last - (!next)
              val returnSize =
                  if available <= required then available else required
              val returnArray = A.array (returnSize, 0w0)
              val _ =
                  A.copy
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
        fun receiveVector required =
            let
              val available = last - (!next)
              val returnSize =
                  if available <= required then available else required
              val returnVector =
                  A.extract (buffer, !next, SOME returnSize)
              val _ = next := (!next) + returnSize
            in
              returnVector
            end
        fun close () = ()
        fun isEOF () = (!next) = last
      in
        {
          receive = receive,
          receiveArray = receiveArray,
          receiveVector = receiveVector,
          close = close,
          isEOF = isEOF
        } : ChannelTypes.InputChannel
      end          

  fun openIn {buffer} = openSliceIn {buffer = buffer, start = 0, lenOpt = NONE}

  (***************************************************************************)

end
