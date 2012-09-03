(**
 * implementation of channel on a text IO stream.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: TextIOChannel.sml,v 1.8 2007/12/04 06:35:46 kiyoshiy Exp $
 *)
structure TextIOChannel =
struct

  (***************************************************************************)

  type InitialInputParameter =
       {
         inStream : TextIO.instream
       }

  type InitialOutputParameter =
       {
         outStream : TextIO.outstream
       }

  (***************************************************************************)

  fun openIn {inStream} =
      let
          fun receive () =
              case TextIO.input1 inStream of
                  NONE => NONE
                | SOME char => SOME(Word8.fromInt(Char.ord char))
          fun receiveArray required =
              let
                  val string = TextIO.inputN (inStream, required)
              in
                  (Word8Array.fromList o (List.map (Word8.fromInt o Char.ord)))
                  (String.explode string)
              end
          fun receiveVector required =
              let
                  val string = TextIO.inputN (inStream, required)
              in
                Byte.stringToBytes string
              end

          fun getLine () =
              case TextIO.inputLine inStream
               of NONE => ""
                | SOME string => string

          (* we do not close, because the steram is not opened by this module*)
          fun close () = ()

          fun isEOF () = TextIO.endOfStream inStream
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
          } : ChannelTypes.InputChannel
      end

  fun openOut {outStream} =
      let
          fun send word =
              let val char = Char.chr(Word8.toInt word)
              in
                TextIO.output1 (outStream, char)
              end
          fun sendArray array = Word8Array.app send array
          fun sendVector vector =
              TextIO.output (outStream, Byte.bytesToString vector)
          fun print string = TextIO.output (outStream, string)
          fun flush () = TextIO.flushOut outStream
          (* we do not close, because the steram is not opened by this module*)
          fun close () = ()
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
          } : ChannelTypes.OutputChannel
      end

  (***************************************************************************)

end
