(**
 * an implementation of FFI_SOCKET for sparc-solaris environment.
 * @author YAMATODANI Kiyoshi
 * @version $Id: FFISocket_solaris.sml,v 1.2.2.1 2007/03/26 11:23:23 sasano Exp $
 *)
structure FFISocket : FFI_SOCKET =
struct

  (***************************************************************************)

  structure UM = UnmanagedMemory

  (***************************************************************************)

  (**
   *  <code>sockaddr_in</code>.
   * <p>
   * In <code>netinet/in.h</code>, <code>sockaddr_in</code> is defined as
   * follows.
   * <pre>
   * typedef unsigned short  sa_family_t;
   * typedef uint16_t        in_port_t;
   * typedef uint32_t        in_addr_t;
   * struct sockaddr_in {
   *        sa_family_t     sin_family;
   *        in_port_t       sin_port;
   *        struct          in_addr sin_addr;
   *        char            sin_zero[8];
   * };
   * </pre>
   * </p>
   *)
  type socketAddress =
       (
         (** sin_family, sin_port *) word
         * (** in_addr *) word
         * (** zero *) word
         * (** zero *) word
       )
  type IPAddress = word * word * word * word
  type family = word
  type socketType = word
  type socket = word

  (***************************************************************************)

  val SizeOfSocketAddress = 0w16

  (**
   * Constant  IPAddress defined in <code>netinet/in.h</code>.
   * <pre>
   * #define INADDR_ANY               0x00000000U
   * </pre>
   *)
  val INADDR_ANY = (0w0, 0w0, 0w0, 0w0) : IPAddress

  (**
   * Constant  IPAddress defined in <code>netinet/in.h</code>.
   * <pre>
   * #define INADDR_LOOPBACK         0x7F000001U
   * </pre>
   *)
  val INADDR_LOOPBACK = (0w127, 0w0, 0w0, 0w1) : IPAddress

  (**
   * A constant defined in <code>sys/socket.h</code>.
   * <pre>
   * #define AF_INET          2
   * </pre>
   *)
  val AF_INET = 0w2 : family

  (**
   * A constant defined in <code>sys/socket.h</code>.
   * <pre>
   * #define       SOCK_STREAM     2
   * </pre>
   *)
  val SOCK_STREAM = 0w2 : socketType

  fun hton16 word = word
  fun htonAddr ((ad1, ad2, ad3, ad4) : IPAddress) =
      foldl
          Word.orb
          0w0
          [Word.<<(ad1, 0w24), Word.<<(ad2, 0w16), Word.<<(ad3, 0w8), ad4]
  fun makeSockAddr {family : family, port, addr} =
      let
        val netPort = hton16 port
        val netAddr = htonAddr addr
      in
        (Word.orb(Word.<<(family, 0w16), netPort), netAddr, 0w0, 0w0)
        : socketAddress
      end
  val ZeroAddr = (0w0, 0w0, 0w0, 0w0) : socketAddress

  (****************************************)

  (* for unix *)
  val libCName = "libsocket.so"
  (*  
   (* for linux *)
   val libCName = "libc.so.6"
   *)
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
  (* Because the C function 'accept' overwrites the address argument,
   * an address argument value can not be passed to it directly.
   * So, we allocate a block in external memory, copy the contents of the
   * address argument into it and pass it to the 'accept' function.
   * And, on return from 'accept', we build an address tuple from the elements
   * of the external memory block.
   *)
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
