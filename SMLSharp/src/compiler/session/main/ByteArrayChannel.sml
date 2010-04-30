(**
 * implementation of channel on a byte array.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ByteArrayChannel.sml,v 1.10 2007/12/04 06:35:46 kiyoshiy Exp $
 *)
structure ByteArrayChannel =
struct

  (***************************************************************************)

  structure CU = ChannelUtility
  structure V = Word8Vector
  structure A = Word8Array
  structure VS = Word8VectorSlice
  structure AS = Word8ArraySlice
  structure EA =
      ExtensibleArray(structure A = Word8Array structure AS = Word8ArraySlice 
                      structure V = Word8Vector structure VS = Word8VectorSlice)

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

  fun openOut {buffer = resultRef} =
      let
        val buffer = EA.array (0, 0w0 : Word8.word)
        val next = ref 0
        fun send byte = (EA.update (buffer, !next, byte); next := !next + 1)
        fun sendArray arr =
            (
              EA.copyArray
                  {src = arr, si = 0, dst = buffer, di = !next, len = NONE};
              next := !next + A.length arr
            )
        fun sendVector vec=
            (
              EA.copyVector
                  {src = vec, si = 0, dst = buffer, di = !next, len = NONE};
              next := !next + V.length vec
            )
        val print = CU.mkPrint sendArray
        fun getPos () = Word32.fromInt (!next)
        fun seek (pos, offset) = next := (Word32.toIntX pos) + offset
        fun flush () = ()
        fun close () = resultRef := SOME(EA.toArray buffer)
      in
        {
          send = send,
          sendArray = sendArray,
          sendVector = sendVector,
          print = print,
          getPos = SOME getPos,
          seek = SOME seek,
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
                  AS.copy
                  {
                    src = AS.slice (buffer,!next,SOME returnSize)
                    (*si = !next,
                    len = SOME returnSize*),
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
                  (*A.extract*) AS.vector (AS.slice (buffer, !next, SOME returnSize))
              val _ = next := (!next) + returnSize
            in
              returnVector
            end
        val getLine = CU.mkGetLine receive
        fun getPos () = Word32.fromInt (!next)
        fun seek (pos, offset) = next := (Word32.toIntX pos) + offset
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
