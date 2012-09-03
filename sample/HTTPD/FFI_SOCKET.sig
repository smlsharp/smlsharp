(**
 * socket interface.
 * @author YAMATODANI Kiyoshi
 * @version $Id: FFI_SOCKET.sig,v 1.1 2007/01/02 05:13:01 kiyoshiy Exp $
 *)
signature FFI_SOCKET =
sig

  (***************************************************************************)

  (** socket *)
  type socket

  (** socket type which specifies the communication semantics. *)
  type socketType

  (** socket addres *)
  type socketAddress

  (** address family *)
  type family

  (** IP address *)
  type IPAddress = word * word * word * word

  (***************************************************************************)

  (**
   * unspecified address
   *)
  val INADDR_ANY : IPAddress

  (**
   * loopback address
   *)
  val INADDR_LOOPBACK : IPAddress

  (** internet addres family *)
  val AF_INET : family

  (** stream socket type. *)
  val SOCK_STREAM : socketType

  (** the number of bytes required to allocate a socketAddress. *)
  val SizeOfSocketAddress : word

  (** a constant socket address filled with zeros.
   *)
  val ZeroAddr : socketAddress

  (**
   * create a socket address.
   *)
  val makeSockAddr
      : {addr : IPAddress, family : family, port : word} -> socketAddress

  (**
   * create a socket.
   * @params (family, socketType, protocol)
   * @param family protocol family : AF_INET
   * @param socketType socket type : SOCK_STREAM
   * @param protocol protocol
   * @return a new socket.
   *)
  val socket : family * socketType * word -> socket

  (**
   * close a socket.
   * @params socket
   * @param socket a socket
   * @return 0 if succeeded, ~1 if an error occurred.
   *)
  val close : socket -> int

  (**
   * accept a connection on a socket.
   * @params (socket, socketaddress, lengthRef)
   * @param socket a socket
   * @param socketaddress an address
   * @param lengthRef the number of bytes of the socketaddress.
   *       On return, this is updated to the number of bytes of the returned
   *       address.
   * @return 0 if succeeded, ~1 if an error occurred.
   *)
  val accept : socket * socketAddress ref * word ref -> socket

  (**
   * bind a socket address to a socket.
   * @params (socket, socketaddress, length)
   * @param socket a socket
   * @param socketaddress an address
   * @param length the number of bytes of the socketaddress.
   *        NOTE: use SizeOfSocketAddress for this parameter.
   * @return 0 if succeeded, ~1 if an error occurred.
   *)
  val bind : socket * socketAddress * word -> word

  (**
   * listen for a connections on a socket.
   * @params (socket, backlog)
   * @param socket a socket
   * @param backlog the number of backlog
   * @return 0 if succeeded, ~1 if an error occurred.
   *)
  val listen : socket * word -> word

  (**
   * receive a message from a socket.
   * @params (socket, buffer, size, flag)
   * @param socket a socket
   * @param buffer a buffer to which received message is stored
   * @param size the number of bytes to be received
   * @param flag flag
   * @return the number of bytes received, or ~1 if an error occurred.
   *)
  val recv : socket * Word8Array.array * int * word -> int

  (**
   * send a message from socket.
   * @params (socket, message, size, flag)
   * @param socket a socket
   * @param message message to be sent
   * @param size the number of bytes to be sent
   * @param flag flag
   * @return the number of bytes sent, or ~1 if an error occurred.
   *)
  val send : socket * Word8Array.vector * int * word -> int

  (**
   * print a message describing system error last occurred.
   * @params prefix
   * @param prefix The error message is printed following this prefix.
   *)
  val perror : string -> word

  (***************************************************************************)

end;

