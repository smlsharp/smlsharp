(* posix-text-prim-io.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * This implements the UNIX version of the OS specific text primitive
 * IO structure.  It is implemented by a trivial translation of the
 * binary operations (see posix-bin-prim-io.sml).
 *
 *)
structure TextOSPrimIO
          : sig

              include OS_PRIM_IO

              val stdIn  : unit -> PrimIO.reader
              val stdOut : unit -> PrimIO.writer
              val stdErr : unit -> PrimIO.writer

              val strReader : string -> PrimIO.reader

          end = 
struct

  structure PIO = OSPrimIOBase
  structure PrimIO = TextPrimIO

  type file_desc = PIO.file_desc

  val bufferSzB = 4096

  val mkReader = PIO.mkTextReader
  val mkWriter = PIO.mkTextWriter

  fun openRd name =
      mkReader {fd = PIO.fileOpen(name, "r"), initBlkMode = true, name = name}

  fun openWr name =
      mkWriter
          {
            fd = PIO.fileOpen(name, "w"),
            name = name,
            initBlkMode = true,
            appendMode = false,
            chunkSize = bufferSzB
          }

  fun openApp name =
      mkWriter
          {
            fd = PIO.fileOpen(name, "a"),
            name = name,
            initBlkMode = true,
            appendMode = true,
            chunkSize = bufferSzB
          }

  fun stdIn () =
      mkReader {fd = PIO.getSTDIN 0, initBlkMode = true, name = "<stdIn>"}

  fun stdOut () =
      mkWriter
          {
            fd = PIO.getSTDOUT 0,
            name = "<stdOut>",
            initBlkMode = true,
            appendMode = false,
            chunkSize = bufferSzB
          }

  fun stdErr () =
      mkWriter
          {
            fd = PIO.getSTDERR 0,
            name = "<stdErr>",
            initBlkMode = true,
            appendMode = false,
            chunkSize = bufferSzB
          }

  fun strReader src =
      let
        val pos = ref 0
        val closed = ref false
        fun checkClosed () = if !closed then raise IO.ClosedStream else ()
        val len = String.size src
        val plen = Position.fromInt len
        fun avail () = len - !pos
        fun readV n =
            let
              val p = !pos
              val m = Int.min(n, len-p)
            in
              checkClosed ();
              pos := p+m;
(** NOTE: could use unchecked operations here **)
              String.substring (src, p, m)
            end
        fun readA asl =
            let
              val p = !pos
              val (buf, i, n) = CharArraySlice.base asl
              val m = Int.min(n, len-p)
            in
              checkClosed ();
              pos := p+m;
              CharArraySlice.copyVec
                  {
                    src = CharVectorSlice.slice (src, p, SOME m),
                    dst = buf,
                    di = i
                  };
              m
            end
        fun getPos () = (checkClosed(); Position.fromInt (!pos))
        fun setPos p =
            (
              checkClosed ();
              if p < 0 orelse p > plen
              then raise Subscript
              else pos := Position.toInt p
            )
      in
        PrimIO.RD
            {
              name = "<string>", 
              chunkSize = len,
              readVec = SOME(readV),
              readArr = SOME(readA),
              readVecNB = SOME(SOME o readV),
              readArrNB = SOME(SOME o readA),
              block = SOME(checkClosed),
              canInput = SOME(fn () => (checkClosed(); true)),
              avail = SOME o avail,
              getPos = SOME getPos,
              setPos = SOME setPos,
              endPos = SOME(fn () => (checkClosed(); plen)),
              verifyPos = SOME getPos,
              close = fn () => closed := true,
              ioDesc = NONE
            }
      end

end (* PosixTextPrimIO *)


