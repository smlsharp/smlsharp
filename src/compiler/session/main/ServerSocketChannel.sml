(**
 * implementation of channel using a server socket.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ServerSocketChannel.sml,v 1.3 2006/02/28 16:11:05 kiyoshiy Exp $
 *)
structure ServerSocketChannel =
struct

  (***************************************************************************)

  type InitialParameter =
       {
         (** port number *)
         port : int
       }

  (***************************************************************************)

  (***************************************************************************)

  fun openInOut ({port} : InitialParameter) =
      let
        fun send socket word =
            let
              val array = Word8Array.fromList [word]
              val sendBuffer = {buf = array, i = 0, sz = SOME 1}
            in
              Socket.sendArr (socket, sendBuffer);
              ()
            end
        fun sendArray socket array =
            let
              val sendBuffer = {buf = array, i = 0, sz = NONE}
            in
              Socket.sendArr (socket, sendBuffer);
              ()
            end
        fun receive socket () =
            let
              val vector = Socket.recvVec (socket, 1)
            in
              if 0 = Word8Vector.length vector
              then NONE
              else SOME(Word8Vector.sub (vector, 0))
            end
        fun receiveArray socket bytes =
            let
              val array = Word8Array.array (bytes, 0w0)
              val readBytes =
                  Socket.recvArr
                      (socket, {buf = array,i = 0, sz = SOME bytes})
            in
              if readBytes = bytes
              then array
              else
                let val newArray = Word8Array.array (readBytes, 0w0)
                in
                  (
                    Word8Array.copy
                        {
                          src = array,
                          si = 0,
                          dst = newArray,
                          di = 0,
                          len = SOME(readBytes)
                        };
                    newArray
                  )
                end
            end
        fun isEOF socket () = false
        fun flush () = ()
        local
          val closed = ref false
        in
        fun close socket () =
            if !closed then () else (Socket.close socket; closed := true)
        end

        val address = INetSock.any port
        val serverSocket = INetSock.TCP.socket()
        val _ = Socket.Ctl.setREUSEADDR (serverSocket, true)
        val _ = Socket.bind (serverSocket, address)
        val _ = Socket.listen (serverSocket, 1)

        val (socket, clientAddress) = Socket.accept serverSocket
        val _ = Socket.close serverSocket 

      in
        (
          {
            receive = receive socket,
            receiveArray = receiveArray socket,
            close = close socket,
            isEOF = isEOF socket
          } : ChannelTypes.InputChannel,
          {
            send = send socket,
            sendArray = sendArray socket,
            flush = flush,
            close = close socket
          } : ChannelTypes.OutputChannel
        )
      end

  (***************************************************************************)

end
