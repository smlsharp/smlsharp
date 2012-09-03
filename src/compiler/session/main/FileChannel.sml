(**
 * implementation of channel on a file.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: FileChannel.sml,v 1.5 2007/02/19 04:06:09 kiyoshiy Exp $
 *)
structure FileChannel =
struct

  (***************************************************************************)

  type InitialOutputParameter =
       {
         fileName : string (** name of the file to write *)
       }

  type InitialInputParameter =
       {
         fileName : string (** name of the file to read *)
       }

  (***************************************************************************)

  fun openOut {fileName} =
      let
          val outStream = BinIO.openOut fileName
          fun send word = BinIO.output1 (outStream, word)
          fun sendArray array = 
              BinIO.output (outStream, Word8Array.extract (array, 0, NONE))
          fun sendVector vector = BinIO.output (outStream, vector)
          fun flush () = BinIO.flushOut outStream
          fun close () = BinIO.closeOut outStream
      in
          {
            send = send,
            sendArray = sendArray,
            sendVector = sendVector,
            flush = flush,
            close = close
          }
      end

  fun openIn {fileName} =
      let
          val inStream = BinIO.openIn fileName
          fun receive () = BinIO.input1 inStream
          fun receiveArray required =
              let
                val vector = BinIO.inputN (inStream, required)
                val array = Word8Array.array (Word8Vector.length vector, 0w0)
              in
                Word8Array.copyVec
                    {src = vector, dst = array, si = 0, di = 0, len = NONE};
                array
              end
          fun receiveVector required = BinIO.inputN (inStream, required)
          fun close () = BinIO.closeIn inStream
          fun isEOF () = BinIO.endOfStream inStream
      in
          {
            receive = receive,
            receiveArray = receiveArray,
            receiveVector = receiveVector,
            close = close,
            isEOF = isEOF
          }
      end

  (***************************************************************************)

end
