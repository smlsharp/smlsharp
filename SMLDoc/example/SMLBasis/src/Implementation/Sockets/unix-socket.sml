(* unix-socket.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 *)

local
    structure Int = IntImp
    structure OS = OSImp
in
structure SocketImp : SOCKET =
  struct

    structure CI = CInterface
    structure W8A = Word8Array
    structure W8V = Word8Vector

    fun sockFn x = CI.c_function "SMLNJ-Sockets" x

    type w8vector = W8V.vector
    type w8array = W8A.array

  (* the system's representation of a socket *)
    type sockFD = PreSock.socket

  (* to inherit the various socket related types *)
    open PreSock

  (* bind socket C functions *)
    fun netdbFun x = CI.c_function "SMLNJ-Sockets" x

(*    val dummyAddr = ADDR(W8V.fromList[]) *)

  (* witness types for the socket parameter *)
    datatype dgram = DGRAM
    datatype 'a stream = STREAM
    datatype passive = PASSIVE
    datatype active = ACTIVE

  (* address families *)
    structure AF =
      struct
	type addr_family = PreSock.addr_family
	val listAddrFamilies : unit -> CI.system_const list
	      = sockFn "listAddrFamilies"
	fun list () =
	      List.map (fn arg => (#2 arg, AF arg)) (listAddrFamilies ())
        fun toString (AF(_, name)) = name
	fun fromString name = (
	      case CI.findSysConst(name, listAddrFamilies ())
	       of NONE => NONE
		| (SOME af) => SOME(AF af)
	      (* end case *))
      end

  (* socket types *)
    structure SOCK =
      struct
	type sock_type = PreSock.sock_type
	val listSockTypes : unit -> CI.system_const list
	      = sockFn "listSockTypes"
	val stream = SOCKTY(CI.bindSysConst ("STREAM", listSockTypes ()))
	val dgram = SOCKTY(CI.bindSysConst ("DGRAM", listSockTypes ()))
	fun list () =
	      List.map (fn arg => (#2 arg, SOCKTY arg)) (listSockTypes ())
	fun toString (SOCKTY(_, name)) = name
	fun fromString name = (case CI.findSysConst(name, listSockTypes ())
	       of NONE => NONE
		| (SOME ty) => SOME(SOCKTY ty)
	      (* end case *))
      end

  (* socket control operations *)
    structure Ctl =
      struct
	local
	  fun getOpt ctlFn (PreSock.SOCK fd) = ctlFn(fd, NONE)
	  fun setOpt ctlFn (PreSock.SOCK fd, value) =
	        ignore(ctlFn(fd, SOME value))
	  val ctlDEBUG     : (sockFD * bool option) -> bool =
		sockFn "ctlDEBUG"
	  val ctlREUSEADDR : (sockFD * bool option) -> bool =
		sockFn "ctlREUSEADDR"
	  val ctlKEEPALIVE : (sockFD * bool option) -> bool =
		sockFn "ctlKEEPALIVE"
	  val ctlDONTROUTE : (sockFD * bool option) -> bool =
		sockFn "ctlDONTROUTE"
	  val ctlLINGER    : (sockFD * int option option) -> int option =
		sockFn "ctlLINGER"
	  val ctlBROADCAST : (sockFD * bool option) -> bool =
		sockFn "ctlBROADCAST"
	  val ctlOOBINLINE : (sockFD * bool option) -> bool =
		sockFn "ctlOOBINLINE"
	  val ctlSNDBUF    : (sockFD * int option) -> int =
		sockFn "ctlSNDBUF"
	  val ctlRCVBUF    : (sockFD * int option) -> int =
		sockFn "ctlSNDBUF"
	in
      (* get/set socket options *)
	fun getDEBUG x = getOpt ctlDEBUG x
	fun setDEBUG x = setOpt ctlDEBUG x
	fun getREUSEADDR x = getOpt ctlREUSEADDR x
	fun setREUSEADDR x = setOpt ctlREUSEADDR x
	fun getKEEPALIVE x = getOpt ctlKEEPALIVE x
	fun setKEEPALIVE x = setOpt ctlKEEPALIVE x
	fun getDONTROUTE x = getOpt ctlDONTROUTE x
	fun setDONTROUTE x = setOpt ctlDONTROUTE x
	fun getLINGER sock = (case (getOpt ctlLINGER sock)
	       of NONE => NONE
		| (SOME t) => SOME (TimeImp.fromSeconds (Int.toLarge t))
	      (* end case *))
(* NOTE: probably shoud do some range checking on the argument *)
	fun setLINGER (sock, NONE) = setOpt ctlLINGER (sock, NONE)
	  | setLINGER (sock, SOME t) =
	      setOpt ctlLINGER (sock,SOME(Int.fromLarge(TimeImp.toSeconds t)))
	fun getBROADCAST x = getOpt ctlBROADCAST x
	fun setBROADCAST x = setOpt ctlBROADCAST x
	fun getOOBINLINE x = getOpt ctlOOBINLINE x
	fun setOOBINLINE x = setOpt ctlOOBINLINE x
	fun getSNDBUF x = getOpt ctlSNDBUF x
(* NOTE: probably shoud do some range checking on the argument *)
	fun setSNDBUF x = setOpt ctlSNDBUF x
	fun getRCVBUF x = getOpt ctlRCVBUF x
(* NOTE: probably shoud do some range checking on the argument *)
	fun setRCVBUF x = setOpt ctlRCVBUF x
	local
	  val getTYPE'  : sockFD -> CI.system_const = sockFn "getTYPE"
	  val getERROR' : sockFD -> bool = sockFn "getERROR"
	in
        fun getTYPE (SOCK fd) = SOCKTY(getTYPE' fd)
        fun getERROR (SOCK fd) = getERROR' fd
	end (* local *)

	local
	  val getPeerName' : sockFD -> addr = sockFn "getPeerName"
	  val getSockName' : sockFD -> addr = sockFn "getSockName"
	  fun getName f (SOCK fd) = ADDR(f fd)
	in
	fun getPeerName	sock = getName getPeerName' sock
	fun getSockName	sock = getName getSockName' sock
	end

	local
	  val setNBIO'   : (sockFD * bool) -> unit = sockFn "setNBIO"
	  val getNREAD'  : sockFD -> int = sockFn "getNREAD"
	  val getATMARK' : sockFD -> bool = sockFn "getATMARK"
	in
	fun setNBIO (SOCK fd, flg) = setNBIO'(fd, flg)
	fun getNREAD (SOCK fd) = getNREAD' fd
	fun getATMARK (SOCK fd) = getATMARK' fd
	end

	end (* local *)
      end (* Ctl *)

  (* socket address operations *)
    fun sameAddr (ADDR a1, ADDR a2) = (a1 = a2)
    local
      val getAddrFamily : addr -> af = sockFn "getAddrFamily"
    in
    fun familyOfAddr (ADDR a) = AF(getAddrFamily a)
    end

  (* socket management *)
    local
      val accept'	: int -> (int * addr)	= sockFn "accept"
      val bind'		: (int * addr) -> unit	= sockFn "bind"
      val connect'	: (int * addr) -> unit	= sockFn "connect"
      val listen'	: (int * int) -> unit	= sockFn "listen"
      val close'	: int -> unit		= sockFn "close"
    in
    fun accept (SOCK fd) = let
	  val (newFD, addr) = accept' fd
	  in
	    (SOCK newFD, ADDR addr)
	  end
    fun bind (SOCK fd, ADDR addr) = bind' (fd, addr)
    fun connect (SOCK fd, ADDR addr) = connect' (fd, addr)
(** Should do some range checking on backLog *)
    fun listen (SOCK fd, backLog) = listen' (fd, backLog)
    fun close (SOCK fd) = close' fd
    end

    datatype shutdown_mode = NO_RECVS | NO_SENDS | NO_RECVS_OR_SENDS
    local
      val shutdown' : (int * int) -> unit = sockFn "shutdown"
      fun how NO_RECVS = 0
	| how NO_SENDS = 1
	| how NO_RECVS_OR_SENDS = 2
    in
    fun shutdown (SOCK fd, mode) = shutdown' (fd, how mode)
    end

    fun pollDesc (SOCK fd) = Option.valOf(OS.IO.pollDesc(PreOS.IO.IODesc fd))

  (* Sock I/O option types *)
    type out_flags = {don't_route : bool, oob : bool}
    type in_flags = {peek : bool, oob : bool}

    type 'a buf = {buf : 'a, i : int, sz : int option}

    local
      fun chk (len, buf, i, NONE) =
	    if ((i < 0) orelse (len < i))
	      then raise Subscript
	      else (buf, i, len - i)
	| chk (len, buf, i, SOME sz) =
	    if ((i < 0) orelse (sz < 0) orelse (len-i < sz))
	      then raise Subscript
	      else (buf, i, sz)
    in
    fun vbuf {buf, i, sz} = chk (W8V.length buf, buf, i, sz)
    fun abuf {buf, i, sz} = chk (W8A.length buf, buf, i, sz)
    end (* local *)

  (* default flags *)
    val dfltDon'tRoute = false
    val dfltOOB = false
    val dfltPeek = false

  (* Sock output operations *)
    local
      val sendV : (int * w8vector * int * int * bool * bool) -> int
	    = sockFn "sendBuf"
      val sendA : (int * w8array * int * int * bool * bool) -> int
	    = sockFn "sendBuf"
    in
    fun sendVec (SOCK fd, buffer) = let
	  val (vec, i, len) = vbuf buffer
	  in
	    if (len > 0) then sendV (fd, vec, i, len, dfltDon'tRoute, dfltOOB) else 0
	  end
    fun sendArr (SOCK fd, buffer) = let
	  val (arr, i, len) = abuf buffer
	  in
	    if (len > 0) then sendA (fd, arr, i, len, dfltDon'tRoute, dfltOOB) else 0
	  end
    fun sendVec' (SOCK fd, buffer, {don't_route, oob}) = let
	  val (vec, i, len) = vbuf buffer
	  in
	    if (len > 0) then sendV (fd, vec, i, len, don't_route, oob) else 0
	  end
    fun sendArr' (SOCK fd, buffer, {don't_route, oob}) = let
	  val (arr, i, len) = abuf buffer
	  in
	    if (len > 0) then sendA (fd, arr, i, len, don't_route, oob) else 0
	  end
    end (* local *)

    local
      val sendToV : (int * w8vector * int * int * bool * bool * addr) -> int
	    = sockFn "sendBufTo"
      val sendToA : (int * w8array * int * int * bool * bool * addr) -> int
	    = sockFn "sendBufTo"
    in
    fun sendVecTo (SOCK fd, ADDR addr, buffer) = let
	  val (vec, i, len) = vbuf buffer
	  in
	    if (len > 0)
	      then sendToV(fd, vec, i, len, dfltDon'tRoute, dfltOOB, addr)
	      else 0
	  end
    fun sendArrTo (SOCK fd, ADDR addr, buffer) = let
	  val (arr, i, len) = abuf buffer
	  in
	    if (len > 0)
	      then sendToA(fd, arr, i, len, dfltDon'tRoute, dfltOOB, addr)
	      else 0
	  end
    fun sendVecTo' (SOCK fd, ADDR addr, buffer, {don't_route, oob}) = let
	  val (vec, i, len) = vbuf buffer
	  in
	    if (len > 0)
	      then sendToV(fd, vec, i, len, don't_route, oob, addr)
	      else 0
	  end
    fun sendArrTo' (SOCK fd, ADDR addr, buffer, {don't_route, oob}) = let
	  val (arr, i, len) = abuf buffer
	  in
	    if (len > 0)
	      then sendToA(fd, arr, i, len, don't_route, oob, addr)
	      else 0
	  end
    end (* local *)

  (* Sock input operations *)
    local
      val recvV' : (int * int * bool * bool) -> w8vector
	    = sockFn "recv"
      fun recvV (_, 0, _, _) = W8V.fromList[]
	| recvV (SOCK fd, nbytes, peek, oob) = if (nbytes < 0)
	    then raise Subscript
	    else recvV' (fd, nbytes, peek, oob)
      val recvA : (int * w8array * int * int * bool * bool) -> int
	    = sockFn "recvBuf"
    in
    fun recvVec (sock, sz) = recvV (sock, sz, dfltPeek, dfltOOB)
    fun recvArr (SOCK fd, buffer) = let
	  val (buf, i, sz) = abuf buffer
	  in
	    if (sz > 0)
	      then recvA(fd, buf, i, sz, dfltPeek, dfltOOB)
	      else 0
	  end
    fun recvVec' (sock, sz, {peek, oob}) = recvV (sock, sz, peek, oob)
    fun recvArr' (SOCK fd, buffer, {peek, oob}) = let
	  val (buf, i, sz) = abuf buffer
	  in
	    if (sz > 0) then recvA(fd, buf, i, sz, peek, oob) else 0
	  end
    end (* local *)

    local
      val recvFromV' : (int * int * bool * bool) -> (w8vector * addr)
	    = sockFn "recvFrom"
      fun recvFromV (_, 0, _, _) = (W8V.fromList[], (ADDR(W8V.fromList[])))
	| recvFromV (SOCK fd, sz, peek, oob) = if (sz < 0)
	    then raise Size
	    else let
	      val (data, addr) = recvFromV' (fd, sz, peek, oob)
	      in
		(data, ADDR addr)
	      end
      val recvFromA : (int * w8array * int * int * bool * bool) -> (int * addr)
	    = sockFn "recvBufFrom"
    in
    fun recvVecFrom (sock, sz) = recvFromV (sock, sz, dfltPeek, dfltOOB)
    fun recvArrFrom (SOCK fd, {buf, i}) = let
	  val (buf, i, sz) = abuf{buf=buf, i=i, sz=NONE}
	  in
	    if (sz > 0)
	      then let
		val (n, addr) = recvFromA(fd, buf, i, sz, dfltPeek, dfltOOB)
	        in
		  (n, ADDR addr)
		end
	      else (0, (ADDR(W8V.fromList[])))
	  end
    fun recvVecFrom' (sock, sz, {peek, oob}) = recvFromV (sock, sz, peek, oob)
    fun recvArrFrom' (SOCK fd, {buf, i}, {peek, oob}) = let
	  val (buf, i, sz) = abuf{buf=buf, i=i, sz=NONE}
	  in
	    if (sz > 0)
	      then let val (n, addr) = recvFromA(fd, buf, i, sz, peek, oob)
	        in
		  (n, ADDR addr)
		end
	      else (0, (ADDR(W8V.fromList[])))
	  end
    end (* local *)

  end (* Socket *)
end

