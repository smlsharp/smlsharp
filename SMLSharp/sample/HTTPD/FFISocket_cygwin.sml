(**
 * an implementation of FFI_SOCKET for cygwin environment.
 * @author YAMATODANI Kiyoshi
 * @version $Id: FFISocket_cygwin.sml,v 1.2 2007/03/04 03:08:46 kiyoshiy Exp $
 *)
structure FFISocket : FFI_SOCKET =
struct

  (***************************************************************************)

  structure UM = UnmanagedMemory

  (***************************************************************************)

  type socketAddress =
       (
         (* sin_family, sin_port *) word
         * (* in_addr *) word
         * (* zero *) word
         * (* zero *) word
       )
  type IPAddress = word * word * word * word
  type family = word
  type socketType = word
  type socket = word

  (***************************************************************************)

  val SizeOfSocketAddress = 0w16
  val INADDR_ANY = (0w0, 0w0, 0w0, 0w0) : IPAddress
  val INADDR_LOOPBACK = (0w127, 0w0, 0w0, 0w1) : IPAddress
  val AF_INET = 0w2 : family
  val SOCK_STREAM = 0w1 : socketType

  fun hton16 word = 
      Word.orb(Word.<<(word, 0w8), Word.andb(Word.>>(word, 0w8), 0wxFF))
  fun htonAddr ((ad1, ad2, ad3, ad4) : IPAddress) =
      foldl
          Word.orb
          0w0
          [Word.<<(ad4, 0w24), Word.<<(ad3, 0w16), Word.<<(ad2, 0w8), ad1]
  fun makeSockAddr {family : family, port, addr} =
      let
        val netPort = hton16 port
        val netAddr = htonAddr addr
      in
        (Word.orb(Word.<<(netPort, 0w16), family), netAddr, 0w0, 0w0)
        : socketAddress
      end
  val ZeroAddr = (0w0, 0w0, 0w0, 0w0) : socketAddress

  (*************************************************)

  val libCName = "cygwin1.dll" (* for cygwin *)
  val libc = DynamicLink.dlopen libCName

  val fptrSocket = DynamicLink.dlsym (libc, "socket")
  val socket = fptrSocket : _import (family, socketType, word) -> socket
  val fptrBind = DynamicLink.dlsym (libc, "bind")
  val bind = fptrBind : _import (socket, socketAddress, word) -> word
  val fptrListen = DynamicLink.dlsym (libc, "listen")
  val listen = fptrListen : _import (socket, word) -> word
  val fptrPerror = DynamicLink.dlsym (libc, "perror")
  val perror = fptrPerror : _import (string) -> word
  local
    val fptrAccept = DynamicLink.dlsym (libc, "accept")
    val acceptPrim = fptrAccept : _import (socket, word, word ref) -> socket
  in
  fun accept
          (socket, socketAddressRef as ref (ad1, ad2, ad3, ad4), lengthRef) =
      let
        val buffer =
            UM.allocate
                ((* words *) 4
                 * (* bit/word *) Word32.wordSize
                 div (* bits/byte *) 8)
        val _ = UM.updateWord (UM.advance(buffer, 0), ad1)
        val _ = UM.updateWord (UM.advance(buffer, 4), ad2)
        val _ = UM.updateWord (UM.advance(buffer, 8), ad3)
        val _ = UM.updateWord (UM.advance(buffer, 12), ad4)
        val clientSocket =
            acceptPrim (socket, UM.addressToWord buffer, lengthRef)
        val newAd1 = UM.subWord (UM.advance(buffer, 0))
        val newAd2 = UM.subWord (UM.advance(buffer, 4))
        val newAd3 = UM.subWord (UM.advance(buffer, 8))
        val newAd4 = UM.subWord (UM.advance(buffer, 12))
        val _ = UM.release buffer
        val _ = socketAddressRef := (newAd1, newAd2, newAd3, newAd4)
      in
        clientSocket
      end
  end
  val fptrSend = DynamicLink.dlsym (libc, "send")
  val send = fptrSend : _import (socket, Word8Array.vector, int, word) -> int
  val fptrRecv = DynamicLink.dlsym (libc, "recv")
  val recv = fptrRecv : _import (socket, Word8Array.array, int, word) -> int
  val fptrClose = DynamicLink.dlsym (libc, "close")
  val close = fptrClose : _import (socket) -> int

  (***************************************************************************)

end
