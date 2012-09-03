(**
 * implementation of channel using a server socket.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ServerSocketChannel.sml,v 1.10 2007/12/04 06:35:46 kiyoshiy Exp $
 *)
structure ServerSocketChannel =
struct

  (***************************************************************************)

  structure CU = ChannelUtility

  (***************************************************************************)

  type InitialParameter =
       {
         (** port number *)
         port : int
       }

  (***************************************************************************)

  fun openInOut ({port} : InitialParameter) =
      let
        fun send socket word =
            let
              val array = Word8Array.fromList [word]
              val sendBuffer = {buf = array, i = 0, sz = SOME 1}
            in
              Socket.sendArr (socket, Word8ArraySlice.slice (array,0,SOME 1) (*sendBuffer*));
              ()
            end
        fun sendArray socket array =
            let
              val sendBuffer = {buf = array, i = 0, sz = NONE}
            in
              (* Assume streaming socket; send(2) sends all data in array *)
              Socket.sendArr (socket, Word8ArraySlice.slice (array,0,NONE) (*sendBuffer*));
              ()
            end
        fun sendVector socket vector =
            let
              val sendBuffer = {buf = vector, i = 0, sz = NONE}
            in
              Socket.sendVec (socket, Word8VectorSlice.slice (vector,0,NONE) (*sendBuffer*));
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
              fun recv (array, i) =
                  if i >= Word8Array.length array then array
                  else
                    let
                      val buf = {buf = array, i = i, sz = NONE}
                      val n = Socket.recvArr (socket, Word8ArraySlice.slice (array,i,NONE) (*buf*))
                    in
                      if n = 0 then
                        let
                          val newArray = Word8Array.array (i, 0w0)
                        in
                          Word8ArraySlice.copy {src = (Word8ArraySlice.slice (array,0,SOME i)),
                                           (*si = 0,*)
                                           dst = newArray,
                                           di = 0(*,
                                           len = SOME i*)};
                          newArray
                        end
                      else recv (array, i + n)
                    end
            in
              recv (array, 0)
            end
        fun receiveVector socket bytes =
            Word8ArraySlice.vector (Word8ArraySlice.slice  (receiveArray socket bytes, 0, NONE))

        fun isEOF socket () = false
        fun flush () = ()
        local
          val closed = ref false
        in
        fun close socket () =
            if !closed then () else (Socket.close socket; closed := true)
        end

        (* Note : The following causes a security hole, because a socket bound
         * to INetSock.any accepts any connection from remote hosts.
         *)
        (*
        val address = INetSock.any port
         *)
        (* Only local connection within the local host should be accepted. *)
        val address =
            INetSock.toAddr (valOf(NetHostDB.fromString "127.0.0.1"), port)
        val serverSocket = INetSock.TCP.socket()
        val _ = Socket.Ctl.setREUSEADDR (serverSocket, true)
        val _ = Socket.bind (serverSocket, address)
        val _ = Socket.listen (serverSocket, 1)

        val (socket, clientAddress) = Socket.accept serverSocket
        val _ = Socket.close serverSocket 

        val getLine = CU.mkGetLine (receive socket)
        val print = CU.mkPrint (sendArray socket)
      in
        (
          {
            receive = receive socket,
            receiveArray = receiveArray socket,
            receiveVector = receiveVector socket,
            getLine = getLine,
            getPos = NONE,
            seek = NONE,
            close = close socket,
            isEOF = isEOF socket
          } : ChannelTypes.InputChannel,
          {
            send = send socket,
            sendArray = sendArray socket,
            sendVector = sendVector socket,
            print = print,
            getPos = NONE,
            seek = NONE,
            flush = flush,
            close = close socket
          } : ChannelTypes.OutputChannel
        )
      end

  (***************************************************************************)

end
