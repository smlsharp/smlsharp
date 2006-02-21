(**
 * base implementation of BinOSPrimIO and TextOSPrimIO structures.
 * @author AT&T Bell Laboratories.
 * @author YAMATODANI Kiyoshi
 * @version $Id: OSPrimIOBase.sml,v 1.8 2005/12/12 14:54:24 kiyoshiy Exp $
 *)
(* posix-io.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * Structure for POSIX 1003.1 primitive I/O operations
 *
 *)
structure OSPrimIOBase =
struct

  (***************************************************************************)

  type word = SysWord.word

  type file_desc = word

  (***************************************************************************)

  val getSTDIN = GenericOS_getSTDIN
  val getSTDOUT = GenericOS_getSTDOUT
  val getSTDERR = GenericOS_getSTDERR
  val fileClose : file_desc -> unit = GenericOS_fileClose
  val read' : file_desc * int -> Word8Vector.vector =
      fn (desc, bytes) =>
         _cast(GenericOS_fileRead (desc, bytes)) : Word8Vector.vector
  val readbuf' : file_desc * Word8Array.array * int * int -> int =
      fn (desc, array, start, size) =>
         GenericOS_fileReadBuf
             (desc, _cast (array) : byteArray, start, size)
  val writeVector : (file_desc * Word8Vector.vector * int * int) -> int =
      fn (desc, array, start, size) =>
         GenericOS_fileWrite (desc, _cast (array) : byteArray, start, size)
  val writeArray : (file_desc * Word8Array.array * int * int) -> int =
      fn (desc, array, start, size) =>
         GenericOS_fileWrite (desc, _cast (array) : byteArray, start, size)
  val fsetPos : file_desc * int -> int = GenericOS_fileSetPosition
  val fgetPos : file_desc -> int = GenericOS_fileGetPosition
  val fileno : file_desc -> int = GenericOS_fileNo
  val fileSize : file_desc -> int = GenericOS_fileSize
  val fileOpen : string * string -> file_desc = GenericOS_fileOpen

  (********************)

  fun readArr (fd, asl) =
      let val (buf, i, len) = Word8ArraySlice.base asl
      in readbuf' (fd, buf, i, len)
      end
  fun readVec (fd,cnt) = if cnt < 0 then raise Size else read'(fd, cnt)

  fun writeArraySlice (fd, asl) =
      let val (buf, i, len) = Word8ArraySlice.base asl
      in writeArray (fd, buf, i, len)
      end
  fun writeVectorSlice (fd, vsl) =
      let val (buf, i, len) = Word8VectorSlice.base vsl
      in writeVector (fd, buf, i, len)
      end

  val bufferSzB = 4096

  fun posFns (closed, fd) =
      let
        val pos = ref (Position.fromInt 0)
        fun getPos () = !pos
        fun setPos p =
            if !closed
            then raise IO.ClosedStream
            else pos := fsetPos (fd, p)
        fun endPos () = if !closed then raise IO.ClosedStream else fileSize fd
        fun verifyPos () =
            let val curPos = fgetPos fd in pos := curPos; curPos end
      in
(*
        ignore (verifyPos ());
*)
        {
          pos = pos,
          getPos = SOME getPos,
          setPos = SOME setPos,
          endPos = SOME endPos,
          verifyPos = SOME verifyPos
        }
      end

  fun mkReader {mkRD, cvtVec, cvtArrSlice} {fd, initBlkMode, name} =
      let
        val closed = ref false
        val {pos, getPos, setPos, endPos, verifyPos} = posFns (closed, fd)
        fun incPos k = pos := Position.+(!pos, Position.fromInt k)
        fun r_readVec n =
            let val v = readVec(fd, n)
            in incPos (Word8Vector.length v); cvtVec v
            end
        fun r_readArr arg =
            let val k = readArr(fd, cvtArrSlice arg)
            in incPos k; k
            end
        fun r_close () = if !closed then () else (closed := true; fileClose fd)
        fun avail () =
            if !closed
            then SOME 0
            else SOME(Position.toInt (fileSize fd) - !pos)
      in
        mkRD
            {
              name = name,
              chunkSize = bufferSzB,
              readVec = SOME r_readVec,
              readArr = SOME r_readArr,
              readVecNB = NONE,
              readArrNB = NONE,
              block = NONE,
              canInput = NONE,
              avail = avail,
              getPos = getPos,
              setPos = setPos,
              endPos = endPos,
              verifyPos = verifyPos,
              close = r_close,
              ioDesc = SOME (IODesc(fileno fd))
            }
        end

    fun mkWriter
            {mkWR, cvtVecSlice, cvtArrSlice}
            {fd, name, initBlkMode, appendMode, chunkSize} =
        let
          val closed = ref false
          val {pos, getPos, setPos, endPos, verifyPos} = posFns (closed, fd)
          fun incPos k = (pos := Position.+(!pos, Position.fromInt k); k)
          fun ensureOpen () = if !closed then raise IO.ClosedStream else ()
          fun writeVector (fd, s) = writeVectorSlice (fd, cvtVecSlice s)
          fun writeArray (fd, s) = writeArraySlice (fd, cvtArrSlice s)
          fun putV x = incPos (writeVector x)
          fun putA x = incPos (writeArray x)
          fun write put arg = (ensureOpen(); put(fd, arg))
          fun w_close () =
              if !closed then () else (closed := true; fileClose fd)
        in
          mkWR
              {
                name = name,
                chunkSize = chunkSize,
                writeVec = SOME(write putV),
                writeArr = SOME(write putA),
                writeVecNB = NONE,
                writeArrNB = NONE,
                block = NONE,
                canOutput = NONE,
                getPos = getPos,
                setPos = setPos,
                endPos = endPos,
                verifyPos = verifyPos,
                ioDesc = SOME (IODesc(fileno fd)),
                close = w_close
              }
        end

    local
      fun c2w_vs cvs =
          let
            val (cv, s, l) = CharVectorSlice.base cvs
            val wv = Byte.stringToBytes cv
          in
            Word8VectorSlice.slice (wv, s, SOME l)
          end

      (* hack!!!  This only works because CharArray.array and
       *          Word8Array.array are really the same internally. *)
      fun c2w_a (array : CharArray.array) =
          _cast (array) : Word8Array.array

      fun c2w_as cas =
          let
            val (ca, s, l) = CharArraySlice.base cas
            val wa = c2w_a ca
          in
            Word8ArraySlice.slice (wa, s, SOME l)
          end
    in

    val mkBinReader =
        mkReader
            {
              mkRD = BinPrimIO.RD,
              cvtVec = fn v => v,
              cvtArrSlice = fn s => s
            }

    val mkTextReader =
        mkReader
            {
              mkRD = TextPrimIO.RD,
              cvtVec = Byte.bytesToString,
              cvtArrSlice = c2w_as
            }

    val mkBinWriter =
        mkWriter
            {
              mkWR = BinPrimIO.WR,
              cvtVecSlice = fn s => s,
              cvtArrSlice = fn s => s
            }

    val mkTextWriter =
        mkWriter
            {
              mkWR = TextPrimIO.WR,
              cvtVecSlice = c2w_vs,
              cvtArrSlice = c2w_as
            }

    end (* local *)

  (***************************************************************************)

end (* structure *)

