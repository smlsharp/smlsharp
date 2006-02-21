(**
 * Copyright (c) 2006, Tohoku University.
 *
 * implementation of channel using a client socket.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ClientSocketChannel.sml,v 1.4 2006/02/18 04:59:28 ohori Exp $
 *)
structure ClientSocketChannel =
struct

  (***************************************************************************)

  type InitialParameter =
       {
         (** name of the host to connect *)
         hostName : string,
         
         (** port number *)
         port : int
       }

  (***************************************************************************)

  exception AddressNotFound of string

  (***************************************************************************)

  fun openInOut ({hostName, port} : InitialParameter) =
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
        fun close closed socket () =
            if !closed then () else (Socket.close socket; closed := true)

        val entry =
            case NetHostDB.getByName hostName of
              SOME(entry) => entry
            | NONE => raise AddressNotFound hostName
        val address = NetHostDB.addr entry
        val addressPortPair = INetSock.toAddr (address, port)
        val socket = INetSock.TCP.socket()
        val _ = Socket.connect (socket, addressPortPair)
        val closed = ref false
      in
        (
          {
            receive = receive socket,
            receiveArray = receiveArray socket,
            close = close closed socket,
            isEOF = isEOF socket
          } : ChannelTypes.InputChannel,
          {
            send = send socket,
            sendArray = sendArray socket,
            flush = flush,
            close = close closed socket
          } : ChannelTypes.OutputChannel
        )
      end

  (***************************************************************************)

end
