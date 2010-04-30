(**
 * implementation of channel on a file.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: FileChannel.sml,v 1.9 2007/12/04 06:35:46 kiyoshiy Exp $
 *)
structure FileChannel =
struct

  (***************************************************************************)

  structure CU = ChannelUtility

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
          fun send byte = BinIO.output1 (outStream, byte)
          fun sendArray array = 
              BinIO.output (outStream, Word8ArraySlice.vector(Word8ArraySlice.slice (array, 0, NONE))) 
          fun sendVector vector = BinIO.output (outStream, vector)
          val print = CU.mkPrint sendArray
          fun flush () = BinIO.flushOut outStream
          fun close () = BinIO.closeOut outStream
      in
          {
            send = send,
            sendArray = sendArray,
            sendVector = sendVector,
            print = print,
            getPos = NONE,
            seek = NONE,
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
                Word8ArraySlice.copyVec
                    {src = Word8VectorSlice.slice (vector,0,NONE), dst = array, (*si = 0,*) di = 0(*, len = NONE*)};
                array
              end
          fun receiveVector required = BinIO.inputN (inStream, required)
          val getLine = CU.mkGetLine receive
          fun close () = BinIO.closeIn inStream
          fun isEOF () = BinIO.endOfStream inStream
      in
          {
            receive = receive,
            receiveArray = receiveArray,
            receiveVector = receiveVector,
            getLine = getLine,
            getPos = NONE,
            seek = NONE,
            close = close,
            isEOF = isEOF
          }
      end

  (***************************************************************************)

end
