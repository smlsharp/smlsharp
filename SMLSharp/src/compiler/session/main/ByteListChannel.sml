(**
 * implementation of channel on a byte list.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ByteListChannel.sml,v 1.10 2007/12/04 06:35:46 kiyoshiy Exp $
 *)
structure ByteListChannel =
struct

  (***************************************************************************)

  structure CU = ChannelUtility

  (***************************************************************************)

  datatype listOrder = NORMAL | REVERSED

  type InitialOutputParameter =
       {
         (** indicates whether 'buffer' is in normal order or in reverse order
          * after 'close' is called.
          *)
         order : listOrder ref,
         buffer : Word8Vector.vector list ref
       }

  type InitialInputParameter =
       {
         buffer : Word8Vector.vector list
       }

  (***************************************************************************)

  (**
   * Opens a channel which accumulates sent bytes to a list.
   * @params {order, buffer}
   * @param order this value is ignored. When 'close' is called, this ref is
   *           updated to the order in which the result list is arranged.
   * @param buffer a ref to byte list. The obtained byte sequence is stored
   *              in this ref when 'close' is called.
   *)
  fun openOut {order, buffer} =
      let
          fun send word =
              buffer := (Word8Vector.fromList [word] :: (!buffer))
          fun sendArray array =
              buffer := Word8Array.vector array :: (!buffer)
          fun sendVector vector =
              buffer := vector :: (!buffer)
          val print = CU.mkPrint sendArray
          fun flush () = ()
          fun close () = (order := REVERSED; buffer := !buffer)
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
          fun receiveVector required =
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
                  Word8Vector.fromList toReturn before remains := toRemain
              end
          val getLine = CU.mkGetLine receive
          fun close () = ()
          fun isEOF () = List.null (!remains)
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

  (***************************************************************************)

end
