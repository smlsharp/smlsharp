(**
 * OS_IO structure.
 * @author AT&T Bell Laboratories.
 * @author YAMATODANI Kiyoshi
 * @version $Id: OS_IO.sml,v 1.7 2008/01/12 09:27:58 kiyoshiy Exp $
 *)
(* os-io.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * NOTE: this interface has been proposed, but not yet adopted by the
 * Standard basis committee.
 *
 *)
structure OS_IO : OS_IO =
struct

  (***************************************************************************)
  structure LI = LargeInt

  (***************************************************************************)

  (* an iodesc is an abstract descriptor for an OS object that
   * supports I/O (e.g., file, tty device, socket, ...).
   *)
  datatype iodesc = datatype iodesc

  datatype iodesc_kind = K of string

  (***************************************************************************)

  (* return a hash value for the I/O descriptor. *)
  fun hash (IODesc fd) = Word.fromInt fd

  (* compare two I/O descriptors *)
  fun compare (IODesc fd1, IODesc fd2) = Int.compare(fd1, fd2)

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
  fun kind (IODesc fd) =
      let
        val fd = SysWord.fromInt fd
      in
        if (SMLSharp.Runtime.GenericOS_isRegFD fd) then Kind.file
        else if (SMLSharp.Runtime.GenericOS_isDirFD fd) then Kind.dir
        else if (SMLSharp.Runtime.GenericOS_isChrFD fd) then Kind.tty
        else if (SMLSharp.Runtime.GenericOS_isBlkFD fd) then Kind.device (*??*)
        else if (SMLSharp.Runtime.GenericOS_isLinkFD fd) then Kind.symlink
        else if (SMLSharp.Runtime.GenericOS_isFIFOFD fd) then Kind.pipe
        else if (SMLSharp.Runtime.GenericOS_isSockFD fd) then Kind.socket
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
    fun join (false, _, w) = w
      | join (true, b, w) = Word.orb(w, b)
    fun test (w, b) = (Word.andb(w, b) <> 0w0)
    val rdBit = SMLSharp.Runtime.GenericOS_getPOLLINFlag 0
    and wrBit = SMLSharp.Runtime.GenericOS_getPOLLOUTFlag 0
    and priBit = SMLSharp.Runtime.GenericOS_getPOLLPRIFlag 0
    fun fromPollDesc (PollDesc(IODesc fd, {rd, wr, pri})) =
        (fd, join (rd, rdBit, join (wr, wrBit, join (pri, priBit, 0w0))))
    fun toPollInfo (fd, w) =
        PollInfo
            (
              IODesc fd,
              {rd = test(w, rdBit), wr = test(w, wrBit), pri = test(w, priBit)}
            )
  in
  fun poll (pds, timeOut) =
      let
        val timeOut =
            case timeOut
             of SOME t =>
                let
                  val usec = Time.toMicroseconds t
                  val sec = LI.div (usec, LI.fromInt 1000000)
                  val usec = LI.mod (usec, LI.fromInt 1000000)
                in
                  SOME (Int32.fromLarge sec, Int.fromLarge usec)
                end
              | NONE => NONE
        val info =
            SMLSharp.Runtime.GenericOS_poll
                (Array.fromList(List.map fromPollDesc pds), timeOut)
          in
        Array.foldr (fn (fdw, infos) => toPollInfo fdw :: infos) [] info
      end
  end (* local *)

  (* check for conditions *)
  fun isIn (PollInfo(_, flgs)) = #rd flgs
  fun isOut (PollInfo(_, flgs)) = #wr flgs
  fun isPri (PollInfo(_, flgs)) = #pri flgs
  fun infoToPollDesc  (PollInfo arg) = PollDesc arg

  (***************************************************************************)

end (* OS_IO *)


