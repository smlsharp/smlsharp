signature SOCKET =
  sig
    type ('a,'b) sock
    type 'a sock_addr
    type dgram
    type 'a stream
    type passive
    type active
    structure AF :
      sig
        type addr_family = NetHostDB.addr_family
        val list : unit -> (string * addr_family) list
        val toString : addr_family -> string
        val fromString : string -> addr_family option
      end
    structure SOCK :
      sig
        eqtype sock_type
        val stream : sock_type
        val dgram : sock_type
        val list : unit -> (string * sock_type) list
        val toString : sock_type -> string
        val fromString : string -> sock_type option
      end
    structure Ctl :
      sig
        val getDEBUG : ('a,'b) sock -> bool
        val setDEBUG : ('a,'b) sock * bool -> unit
        val getREUSEADDR : ('a,'b) sock -> bool
        val setREUSEADDR : ('a,'b) sock * bool -> unit
        val getKEEPALIVE : ('a,'b) sock -> bool
        val setKEEPALIVE : ('a,'b) sock * bool -> unit
        val getDONTROUTE : ('a,'b) sock -> bool
        val setDONTROUTE : ('a,'b) sock * bool -> unit
        val getLINGER : ('a,'b) sock -> Time.time option
        val setLINGER : ('a,'b) sock * Time.time option -> unit
        val getBROADCAST : ('a,'b) sock -> bool
        val setBROADCAST : ('a,'b) sock * bool -> unit
        val getOOBINLINE : ('a,'b) sock -> bool
        val setOOBINLINE : ('a,'b) sock * bool -> unit
        val getSNDBUF : ('a,'b) sock -> int
        val setSNDBUF : ('a,'b) sock * int -> unit
        val getRCVBUF : ('a,'b) sock -> int
        val setRCVBUF : ('a,'b) sock * int -> unit
        val getTYPE : ('a,'b) sock -> SOCK.sock_type
        val getERROR : ('a,'b) sock -> bool
        val getPeerName : ('b,'a) sock -> 'b sock_addr
        val getSockName : ('b,'a) sock -> 'b sock_addr
(* FIXME!
        val setNBIO : ('a,'b) sock * bool -> unit
*)
        val getNREAD : ('a,'b) sock -> int
        val getATMARK : ('a,active stream) sock -> bool
      end
    val sameAddr : 'a sock_addr * 'a sock_addr -> bool
    val familyOfAddr : 'a sock_addr -> AF.addr_family
    val accept : ('a,passive stream) sock
                 -> ('a,active stream) sock * 'a sock_addr
    val bind : ('b,'a) sock * 'b sock_addr -> unit
    val connect : ('b,'a) sock * 'b sock_addr -> unit
    val listen : ('a,passive stream) sock * int -> unit
    val close : ('a,'b) sock -> unit
    datatype shutdown_mode = NO_RECVS | NO_RECVS_OR_SENDS | NO_SENDS
    val shutdown : ('a,'b stream) sock * shutdown_mode -> unit
(* FIXME!
    val pollDesc : ('a,'b) sock -> OS.IO.poll_desc
*)
    type out_flags = {don't_route:bool, oob:bool}
    type in_flags = {oob:bool, peek:bool}
    type 'a buf = {buf:'a, i:int, sz:int option}
    val sendVec : ('a,active stream) sock * Word8Vector.vector buf -> int
    val sendArr : ('a,active stream) sock * Word8Array.array buf -> int
    val sendVec' : ('a,active stream) sock * Word8Vector.vector buf * out_flags
                   -> int
    val sendArr' : ('a,active stream) sock * Word8Array.array buf * out_flags
                   -> int
    val sendVecTo : ('a,dgram) sock * 'a sock_addr * Word8Vector.vector buf
                    -> int
    val sendArrTo : ('a,dgram) sock * 'a sock_addr * Word8Array.array buf
                    -> int
    val sendVecTo' : ('a,dgram) sock * 'a sock_addr * Word8Vector.vector buf
                     * out_flags
                     -> int
    val sendArrTo' : ('a,dgram) sock * 'a sock_addr * Word8Array.array buf
                     * out_flags
                     -> int
    val recvVec : ('a,active stream) sock * int -> Word8Vector.vector
    val recvArr : ('a,active stream) sock * Word8Array.array buf -> int
    val recvVec' : ('a,active stream) sock * int * in_flags
                   -> Word8Vector.vector
    val recvArr' : ('a,active stream) sock * Word8Array.array buf * in_flags
                   -> int
    val recvVecFrom : ('a,dgram) sock * int
                      -> Word8Vector.vector * 'a sock_addr
    val recvArrFrom : ('a,dgram) sock * {buf:Word8Array.array, i:int}
                      -> int * 'a sock_addr
    val recvVecFrom' : ('a,dgram) sock * int * in_flags
                       -> Word8Vector.vector * 'a sock_addr
    val recvArrFrom' : ('a,dgram) sock * {buf:Word8Array.array, i:int}
                       * in_flags
                       -> int * 'a sock_addr
  end
