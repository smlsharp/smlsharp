_interface "os-io.smi"
infix 6 +
infix 4 <> = >=
val op + = SMLSharp.Int.add
val op >= = SMLSharp.Int.gteq
fun op <> (x:word,y) = if x = y then false else true
structure SysWordImp = Word
structure WordImp = Word
structure Int32Imp = Int
structure Int32 = Int
structure IntImp = Int
structure TimeImp = Time
structure IntInfImp =
struct
  open LargeInt
  fun divMod (x, y) =
      let val y = LargeInt.fromInt y
      in (LargeInt.div (x, y), LargeInt.mod (x, y))
      end
end
structure OS =
struct
  structure IO = SMLSharpOSFileSys
end
structure Posix =
struct
  structure FileSys =
  struct
    val wordToFD = SMLSharp.Word.toIntX
    open SMLSharpOSFileSys
  end
end
structure CInterface =
struct
  val prim_poll =
      _import "prim_GenericOS_poll"
      : __attribute__((no_callback))
        (int array, word array,
         int, int) -> int
  fun unzipFDSet (fdset : (int * word) list) =
      let
        val len = List.length fdset
        val fds = SMLSharp.PrimArray.allocArray len
        val evs = SMLSharp.PrimArray.allocArray len
        fun loop (i, nil) = ()
          | loop (i, (fd,ev)::t) =
            (SMLSharp.PrimArray.update (fds, i, fd);
             SMLSharp.PrimArray.update (evs, i, ev);
             loop (i + 1, t))
      in
        loop (0, fdset);
        (fds, evs)
      end
  fun zipFDSet (fdset, evset) =
      let
        val len = SMLSharp.PrimArray.length fdset
        fun loop (i, z) =
            if i >= len then rev z
            else let val ev = SMLSharp.PrimArray.sub (evset, i) : word
                     val fd = SMLSharp.PrimArray.sub (fdset, i) : int
                     val z =  if ev = 0w0 then z else (fd, ev) :: z
                 in loop (i + 1, z)
                 end
      in
        loop (0, nil)
      end
  fun poll (fdset, timeout) =
      let
        val (sec, usec) = case timeout of
                            SOME (sec, usec) => (sec, usec)
                          | NONE => (~1, ~1)
        val (fdset, evset) = unzipFDSet fdset
        val err = prim_poll (fdset, evset, sec, usec)
      in
        zipFDSet (fdset, evset)
      end
  fun c_function (_:string) (_:string) = poll
end

(* os-io.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * NOTE: this interface has been proposed, but not yet adopted by the
 * Standard basis committee.
 *
 *)

local
    structure Word = WordImp
    structure Int32 = Int32Imp
    structure Int = IntImp
    structure SysWord = SysWordImp
in
(*
structure OS_IO : OS_IO =
*)
structure SMLSharpSMLNJ_OS_IO :> OS_IO where type iodesc = SMLSharpOSFileSys.iodesc =
  struct

  (* an iodesc is an abstract descriptor for an OS object that
   * supports I/O (e.g., file, tty device, socket, ...).
   *)
    type iodesc = OS.IO.iodesc

    datatype iodesc_kind = K of string

  (* return a hash value for the I/O descriptor. *)
    fun hash (OS.IO.IODesc fd) = Word.fromInt fd

  (* compare two I/O descriptors *)
    fun compare (OS.IO.IODesc fd1, OS.IO.IODesc fd2) = Int.compare(fd1, fd2)

    structure Kind =
      struct
	val file = K "FILE"
	val dir = K "DIR"
	val symlink = K "LINK"
	val tty = K "TTY"
	val pipe = K "PIPE"
	val socket = K "SOCK"
	val device = K "DEV"
      end

  (* return the kind of I/O descriptor *)
    fun kind (OS.IO.IODesc fd) = let
	  val fd = Posix.FileSys.wordToFD(SysWord.fromInt fd)
	  val stat = Posix.FileSys.fstat fd
	  in
	    if      (Posix.FileSys.ST.isReg stat) then Kind.file
	    else if (Posix.FileSys.ST.isDir stat) then Kind.dir
	    else if (Posix.FileSys.ST.isChr stat) then Kind.tty
	    else if (Posix.FileSys.ST.isBlk stat) then Kind.device (* ?? *)
	    else if (Posix.FileSys.ST.isLink stat) then Kind.symlink
	    else if (Posix.FileSys.ST.isFIFO stat) then Kind.pipe
	    else if (Posix.FileSys.ST.isSock stat) then Kind.socket
	    else K "UNKNOWN"
	  end

    type poll_flags = {rd : bool, wr : bool, pri : bool}
    datatype poll_desc = PollDesc of (iodesc * poll_flags)
    datatype poll_info = PollInfo of (iodesc * poll_flags)

  (* create a polling operation on the given descriptor; note that
   * not all I/O devices support polling, but for the time being, we
   * don't test for this.
   *)
    fun pollDesc iod = SOME(PollDesc(iod, {rd=false, wr=false, pri=false}))

  (* return the I/O descriptor that is being polled *)
    fun pollToIODesc (PollDesc(iod, _)) = iod

    exception Poll

  (* set polling events; if the polling operation is not appropriate
   * for the underlying I/O device, then the Poll exception is raised.
   *)
    fun pollIn (PollDesc(iod, {rd, wr, pri})) =
	  PollDesc(iod, {rd=true, wr=wr, pri=pri})
    fun pollOut (PollDesc(iod, {rd, wr, pri})) =
	  PollDesc(iod, {rd=rd, wr=true, pri=pri})
    fun pollPri (PollDesc(iod, {rd, wr, pri})) =
	  PollDesc(iod, {rd=rd, wr=wr, pri=true})

  (* polling function *)
    local
      val poll' : ((int * word) list * (Int32.int * int) option) -> (int * word) list =
	    CInterface.c_function "POSIX-OS" "poll"
      fun join (false, _, w) = w
        | join (true, b, w) = Word.orb(w, b)
      fun test (w, b) = (Word.andb(w, b) <> 0w0)
      val rdBit = 0w1 and wrBit = 0w2 and priBit = 0w4
      fun fromPollDesc (PollDesc(OS.IO.IODesc fd, {rd, wr, pri})) =
	    ( fd,
	      join (rd, rdBit, join (wr, wrBit, join (pri, priBit, 0w0)))
	    )
      fun toPollInfo (fd, w) = PollInfo(OS.IO.IODesc fd, {
	      rd = test(w, rdBit), wr = test(w, wrBit), pri = test(w, priBit)
	    })
    in
    fun poll (pds, timeOut) = let
	  val timeOut = (case timeOut
		 of SOME t =>
		    let val usec = TimeImp.toMicroseconds t
			val (sec, usec) = IntInfImp.divMod (usec, 1000000)
		    in
			SOME (Int32.fromLarge sec, Int.fromLarge usec)
		    end
		  | NONE => NONE
		(* end case *))
	  val info = poll' (List.map fromPollDesc pds, timeOut)
	  in
	    List.map toPollInfo info
	  end
    end (* local *)

  (* check for conditions *)
    fun isIn (PollInfo(_, flgs)) = #rd flgs
    fun isOut (PollInfo(_, flgs)) = #wr flgs
    fun isPri (PollInfo(_, flgs)) = #pri flgs
    fun infoToPollDesc  (PollInfo arg) = PollDesc arg

  end (* OS_IO *)
end

