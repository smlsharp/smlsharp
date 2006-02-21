(**
 * Copyright (c) 2006, Tohoku University.
 *
 * implementation of channel on a text IO stream.
 * @author YAMATODANI Kiyoshi
 * @version $Id: TextIOChannel.sml,v 1.3 2006/02/18 04:59:28 ohori Exp $
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

          (* we do not close, because the steram is not opened by this module*)
          fun close () = ()

          fun isEOF () = TextIO.endOfStream inStream
      in
          {
            receive = receive,
            receiveArray = receiveArray,
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
          fun flush () = TextIO.flushOut outStream
          (* we do not close, because the steram is not opened by this module*)
          fun close () = ()
      in
          {
            send = send,
            sendArray = sendArray,
            flush = flush,
            close = close
          } : ChannelTypes.OutputChannel
      end

  (***************************************************************************)

end
