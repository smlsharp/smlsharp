(* generic-sock.sig
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 *)

local
    structure Socket = SocketImp
in
signature GENERIC_SOCK =
  sig
    val addressFamilies : unit -> Socket.AF.addr_family list
	(* returns a list of the supported address families; this should include
	 * at least:  Socket.AF.inet.
	 *)

    val socketTypes : unit -> Socket.SOCK.sock_type
	(* returns a list of the supported socket types; this should include at
	 * least:  Socket.SOCK.stream and Socket.SOCK.dgram.
	 *)

  (* create sockets using default protocol *)
    val socket : (Socket.AF.addr_family * Socket.SOCK.sock_type)
	  -> ('a, 'b) Socket.sock
    val socketPair : (Socket.AF.addr_family * Socket.SOCK.sock_type)
	  -> (('a, 'b) Socket.sock * ('a, 'b) Socket.sock)

  (* create sockets using the specified protocol *)
    val socket' : (Socket.AF.addr_family * Socket.SOCK.sock_type * int)
	  -> ('a, 'b) Socket.sock
    val socketPair' : (Socket.AF.addr_family * Socket.SOCK.sock_type * int)
	  -> (('a, 'b) Socket.sock * ('a, 'b) Socket.sock)

  end
end

