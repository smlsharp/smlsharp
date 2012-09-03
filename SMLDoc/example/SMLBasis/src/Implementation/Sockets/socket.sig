(* socket.sig
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 *)

local
    structure OS = OSImp
in
signature SOCKET =
  sig

  (* sockets are polymorphic; the instantiation of the type variables
   * provides a way to distinguish between different kinds of sockets.
   *)
    type ('af, 'sock) sock
    type 'af sock_addr

  (* witness types for the socket parameter *)
    type dgram
    type 'a stream
    type passive	(* for passive streams *)
    type active		(* for active (connected) streams *)

  (* address families *)
    structure AF : sig
	type addr_family = NetHostDB.addr_family
	val list : unit -> (string * addr_family) list
	    (* list known address families *)
        val toString : addr_family -> string
	val fromString : string -> addr_family option
      end

  (* socket types *)
    structure SOCK : sig
	eqtype sock_type
	val stream : sock_type		(* stream sockets *)
	val dgram : sock_type		(* datagram sockets *)
	val list : unit -> (string * sock_type) list
	    (* list known socket types *)
	val toString : sock_type -> string
	val fromString : string -> sock_type option
      end

  (* socket control operations *)
    structure Ctl : sig

      (* get/set socket options *)
        val getDEBUG		: ('a, 'b) sock -> bool
        val setDEBUG		: (('a, 'b) sock * bool) -> unit
        val getREUSEADDR	: ('a, 'b) sock -> bool
        val setREUSEADDR	: (('a, 'b) sock * bool) -> unit
        val getKEEPALIVE	: ('a, 'b) sock -> bool
        val setKEEPALIVE	: (('a, 'b) sock * bool) -> unit
        val getDONTROUTE	: ('a, 'b) sock -> bool
        val setDONTROUTE	: (('a, 'b) sock * bool) -> unit
        val getLINGER		: ('a, 'b) sock -> Time.time option
        val setLINGER		: (('a, 'b) sock * Time.time option) -> unit
        val getBROADCAST	: ('a, 'b) sock -> bool
        val setBROADCAST	: (('a, 'b) sock * bool) -> unit
        val getOOBINLINE	: ('a, 'b) sock -> bool
        val setOOBINLINE	: (('a, 'b) sock * bool) -> unit
        val getSNDBUF		: ('a, 'b) sock -> int
        val setSNDBUF		: (('a, 'b) sock * int) -> unit
        val getRCVBUF		: ('a, 'b) sock -> int
        val setRCVBUF		: (('a, 'b) sock * int) -> unit
        val getTYPE		: ('a, 'b) sock -> SOCK.sock_type
        val getERROR		: ('a, 'b) sock -> bool

	val getPeerName		: ('a, 'b) sock -> 'a sock_addr
	val getSockName		: ('a, 'b) sock -> 'a sock_addr
	val setNBIO		: (('a, 'b) sock * bool) -> unit
	val getNREAD		: ('a, 'b) sock -> int
	val getATMARK		: ('a, active stream) sock -> bool
      end (* Ctl *)

  (* socket address operations *)
    val sameAddr     : ('a sock_addr * 'a sock_addr) -> bool
    val familyOfAddr : 'a sock_addr -> AF.addr_family

  (* socket management *)
    val accept  : ('a, passive stream) sock
		    -> (('a, active stream) sock * 'a sock_addr)
    val bind    : (('a, 'b) sock * 'a sock_addr) -> unit
    val connect : (('a, 'b) sock * 'a sock_addr) -> unit
    val listen  : (('a, passive stream) sock * int) -> unit
    val close   : ('a, 'b) sock -> unit
    datatype shutdown_mode = NO_RECVS | NO_SENDS | NO_RECVS_OR_SENDS
    val shutdown : (('a, 'b stream) sock * shutdown_mode) -> unit

    val pollDesc : ('a, 'b) sock -> OS.IO.poll_desc

  (* Sock I/O option types *)
    type out_flags = {don't_route : bool, oob : bool}
    type in_flags = {peek : bool, oob : bool}

    type 'a buf = {buf : 'a, i : int, sz : int option}

  (* Sock output operations *)
    val sendVec	   : (('a, active stream) sock * Word8Vector.vector buf)
			-> int
    val sendArr	   : (('a, active stream) sock * Word8Array.array buf)
			-> int
    val sendVec'   : (('a, active stream) sock * Word8Vector.vector buf * out_flags)
			-> int
    val sendArr'   : (('a, active stream) sock * Word8Array.array buf * out_flags)
			-> int
    val sendVecTo  : (('a, dgram) sock * 'a sock_addr * Word8Vector.vector buf)
			-> int
    val sendArrTo  : (('a, dgram) sock * 'a sock_addr * Word8Array.array buf)
			-> int
    val sendVecTo' : (('a, dgram) sock * 'a sock_addr * Word8Vector.vector buf * out_flags)
			-> int
    val sendArrTo' : (('a, dgram) sock * 'a sock_addr * Word8Array.array buf * out_flags)
			-> int

  (* Sock input operations *)
    val recvVec      : (('a, active stream) sock * int)
			-> Word8Vector.vector
    val recvArr	     : (('a, active stream) sock * Word8Array.array buf)
			-> int
    val recvVec'     : (('a, active stream) sock * int * in_flags)
			-> Word8Vector.vector
    val recvArr'     : (('a, active stream) sock * Word8Array.array buf * in_flags)
			-> int
    val recvVecFrom  : (('a, dgram) sock * int)
			-> (Word8Vector.vector * 'b sock_addr)
    val recvArrFrom  : (('a, dgram) sock * {buf : Word8Array.array, i : int})
			-> (int * 'a sock_addr)
    val recvVecFrom' : (('a, dgram) sock * int * in_flags)
			-> (Word8Vector.vector * 'b sock_addr)
    val recvArrFrom' : (('a, dgram) sock * {buf : Word8Array.array, i : int} * in_flags)
			-> (int * 'a sock_addr)

  end
end

