(* posix-bin-prim-io.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * This implements the UNIX version of the OS specific binary primitive
 * IO structure.  The Text IO version is implemented by a trivial translation
 * of these operations (see posix-text-prim-io.sml).
 *
 *)

local
    structure Position = PositionImp
    structure OS = OSImp
in	
structure PosixBinPrimIO : OS_PRIM_IO = 
  struct

    structure PrimIO = BinPrimIO

    structure Vec = Word8Vector
    structure PF = Posix.FileSys
    structure PIO = Posix.IO

    type file_desc = PF.file_desc

    val toFPI = Position.fromInt

    fun announce s x y = (
	  (*print "Posix: "; print (s:string); print "\n"; *)
	  x y)

    val bufferSzB = 4096

    fun isRegFile fd = PF.ST.isReg(PF.fstat fd)

    fun posFns (closed, fd) = if (isRegFile fd)
	  then let
	    val pos = ref(Position.fromInt 0)
	    fun getPos () = !pos
	    fun setPos p = (
		  if !closed then raise IO.ClosedStream else ();
		  pos := announce "lseek" PIO.lseek(fd,p,PIO.SEEK_SET))
	    fun endPos () = (
		  if !closed then raise IO.ClosedStream else ();
		  PF.ST.size(announce "fstat" PF.fstat fd))
	    fun verifyPos () = let
		  val curPos = PIO.lseek(fd, Position.fromInt 0, PIO.SEEK_CUR)
		  in
		    pos := curPos; curPos
		  end
	    in
	      ignore (verifyPos());
	      { pos = pos,
		getPos = SOME getPos,
		setPos = SOME setPos,
		endPos = SOME endPos,
		verifyPos = SOME verifyPos
	      }
	    end
	  else {
	      pos = ref(Position.fromInt 0),
	      getPos = NONE, setPos = NONE, endPos = NONE, verifyPos = NONE
	    }

    fun mkReader {fd, name, initBlkMode} = let
	  val closed = ref false
          val {pos, getPos, setPos, endPos, verifyPos} = posFns (closed, fd)
          val blocking = ref initBlkMode
          fun blockingOn () = (PIO.setfl(fd, PIO.O.flags[]); blocking := true)
	  fun blockingOff () = (PIO.setfl(fd, PIO.O.nonblock); blocking := false)
	  fun incPos k = pos := Position.+(!pos, toFPI k)
	  fun readVec n = let
		val v = announce "read" PIO.readVec(fd, n)
		in
		  incPos (Vec.length v); v
		end
	  fun readArr arg = let
		val k = announce "readBuf" PIO.readArr(fd, arg)
		in
		  incPos k; k
		end
	  fun blockWrap f x = (
		if !closed then raise IO.ClosedStream else ();
		if !blocking then () else blockingOn();
		f x)
	  fun noBlockWrap f x = (
		if !closed then raise IO.ClosedStream else ();
		if !blocking then blockingOff() else ();
		((* try *) SOME(f x)
		  handle (e as OS.SysErr(_, SOME cause)) =>
                     if cause = Posix.Error.again then NONE else raise e
		(* end try *)))
	  fun close () = if !closed
		then ()
		else (closed:=true; announce "close" PIO.close fd)
	  val isReg = isRegFile fd
	  fun avail () = if !closed
		  then SOME 0
		else if isReg
		  then SOME(Position.-(PF.ST.size(PF.fstat fd), !pos))
		  else NONE
	  in
	    BinPrimIO.RD{
		name		= name,
		chunkSize	= bufferSzB,
		readVec		= SOME(blockWrap readVec),
		readArr		= SOME(blockWrap readArr),
		readVecNB	= SOME(noBlockWrap readVec),
		readArrNB	= SOME(noBlockWrap readArr),
		block		= NONE,
		canInput	= NONE,
		avail		= avail,
		getPos		= getPos,
		setPos		= setPos,
		endPos		= endPos,
		verifyPos	= verifyPos,
		close		= close,
		ioDesc		= SOME(PF.fdToIOD fd)
	      }
	  end

	     
    fun openRd name = mkReader{
	    fd = announce "openf" PF.openf(name,PIO.O_RDONLY,PF.O.flags[]),
	    name = name,
	    initBlkMode = true
	  }


    fun mkWriter {fd, name, initBlkMode, appendMode, chunkSize} = let
	  val closed = ref false
          val {pos, getPos, setPos, endPos, verifyPos} = posFns (closed, fd)
	  fun incPos k = (pos := Position.+(!pos, toFPI k); k)
	  val blocking = ref initBlkMode
	  val appendFS = PIO.O.flags(if appendMode then [PIO.O.append] else nil)
	  fun updateStatus() = let
		val flgs = if !blocking
		      then appendFS
		      else PIO.O.flags[PIO.O.nonblock, appendFS]
		in
		  announce "setfl" PIO.setfl(fd, flgs)
		end
	  fun ensureOpen () = if !closed then raise IO.ClosedStream else ()
	  fun ensureBlock (x) =
		if !blocking = x then () else (blocking := x; updateStatus())
	  fun putV x = incPos(announce "writeVec" PIO.writeVec x)
	  fun putA x = incPos(announce "writeArr" PIO.writeArr x)
	  fun write (put, block) arg = (
		ensureOpen(); ensureBlock block; 
		put(fd, arg))
	  fun handleBlock writer arg = SOME(writer arg)
		handle (e as OS.SysErr(_, SOME cause)) => 
 		  if cause = Posix.Error.again then NONE else raise e
	  fun close () = if !closed
		then ()
		else (closed:=true; announce "close" PIO.close fd)
	  in
	    BinPrimIO.WR{
		name		= name,
		chunkSize	= chunkSize,
		writeVec	= SOME(write(putV,true)),
		writeArr	= SOME(write(putA,true)),
		writeVecNB	= SOME(handleBlock(write(putV,false))),
		writeArrNB	= SOME(handleBlock(write(putA,false))),
		block		= NONE,
		canOutput	= NONE,
		getPos		= getPos,
		setPos		= setPos,
		endPos		= endPos,
		verifyPos	= verifyPos,
		ioDesc		= SOME(PF.fdToIOD fd),
		close		= close
	      }
	  end

    val standardMode = PF.S.flags[	(* mode 0666 *)
	    PF.S.irusr, PF.S.iwusr,
	    PF.S.irgrp, PF.S.iwgrp,
	    PF.S.iroth, PF.S.iwoth
	  ]
    fun createFile (name, mode, flags) =
	  announce "createf" PF.createf(name, mode, flags, standardMode)

    fun openWr name = mkWriter{
	    fd=createFile(name, PIO.O_WRONLY, PF.O.trunc),
	    name=name,
	    initBlkMode=true,
	    appendMode=false,
	    chunkSize=bufferSzB
	  }

    fun openApp name = mkWriter{
	    fd		= createFile(name, PIO.O_WRONLY, PF.O.append),
	    name	= name,
	    initBlkMode	= true,
	    appendMode	= true,
	    chunkSize	= bufferSzB
	  }

  end (* PosixBinPrimIO *)
end

