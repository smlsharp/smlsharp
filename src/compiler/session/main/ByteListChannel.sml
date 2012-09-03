(**
 * implementation of channel on a byte list.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ByteListChannel.sml,v 1.4 2006/02/28 16:11:04 kiyoshiy Exp $
 *)
structure ByteListChannel =
struct

  (***************************************************************************)

  type InitialOutputParameter =
       {
         buffer : Word8.word list ref
       }

  type InitialInputParameter =
       {
         buffer : Word8.word list
       }

  (***************************************************************************)

  fun openOut {buffer} =
      let
          fun send word = buffer := (word :: (!buffer))
          fun sendArray array =
              Word8Array.foldl
              (fn (word, ()) => buffer := (word :: (!buffer)))
              ()
              array
          fun flush () = ()
          fun close () = buffer := (rev (!buffer))
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
          val remains = ref buffer;
          fun receive () =
              case !remains of
                  [] => NONE
                | (head::tail) => SOME head before remains := tail
          fun receiveArray required =
              let
                  val available = List.length (!remains)
                  val (toReturn, toRemain) = 
                      if available <= required then
                          (!remains, [])
                      else
                          (
                            List.take (!remains, required),
                            List.drop (!remains, required)
                          )
              in
                  Word8Array.fromList toReturn before remains := toRemain
              end
          fun close () = ()
          fun isEOF () = List.null (!remains)
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
