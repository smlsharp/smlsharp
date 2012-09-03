(* generic-sock.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 *)

structure GenericSock : GENERIC_SOCK =
  struct
    structure PS = PreSock

    fun sockFn x = CInterface.c_function "SMLNJ-Sockets" x

  (* returns a list of the supported address families; this should include
   * at least:  Socket.AF.inet.
   *)
    fun addressFamilies () = raise Fail "GenericSock.addressFamilies"

  (* returns a list of the supported socket types; this should include at
   * least:  Socket.SOCK.stream and Socket.SOCK.dgram.
   *)
    fun socketTypes () = raise Fail "GenericSock.socketTypes"

    val c_socket	: (int * int * int) -> PS.socket
	  = sockFn "socket"
    val c_socketPair	: (int * int * int) -> (PS.socket * PS.socket)
	  = sockFn "socketPair"

  (* create sockets using default protocol *)
    fun socket (PS.AF(af, _), PS.SOCKTY(ty, _)) =
	  PS.SOCK(c_socket (af, ty, 0))
    fun socketPair (PS.AF(af, _), PS.SOCKTY(ty, _)) = let
	  val (s1, s2) = c_socketPair (af, ty, 0)
	  in
	    (PS.SOCK s1, PS.SOCK s2)
	  end

  (* create sockets using the specified protocol *)
    fun socket' (PS.AF(af, _), PS.SOCKTY(ty, _), prot) =
	  PS.SOCK(c_socket (af, ty, prot))
    fun socketPair' (PS.AF(af, _), PS.SOCKTY(ty, _), prot) = let
	  val (s1, s2) = c_socketPair (af, ty, prot)
	  in
	    (PS.SOCK s1, PS.SOCK s2)
	  end

  end

