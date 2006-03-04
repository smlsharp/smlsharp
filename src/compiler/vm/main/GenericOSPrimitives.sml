(**
 * implementation of primitives for GenericOS structures.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: GenericOSPrimitives.sml,v 1.11 2006/02/28 16:11:12 kiyoshiy Exp $
 *)
structure GenericOSPrimitives : PRIMITIVE_IMPLEMENTATIONS =
struct

  (***************************************************************************)

  open RuntimeTypes
  open BasicTypes
  structure C = Constants
  structure H = Heap
  structure OF = OS.FileSys
  structure RE = RuntimeErrors
  structure SLD = SourceLanguageDatatypes

  (***************************************************************************)

  fun GenericOS_errorName VM heap [Int syserror] =
      [SLD.stringToValue heap (OS.errorName (SInt32ToInt syserror))]
    | GenericOS_errorName VM heap _ =
      raise RE.UnexpectedPrimitiveArguments "GenericOS_errorName"

  fun GenericOS_errorMsg VM heap [Int syserror] =
      [SLD.stringToValue heap (OS.errorMsg (SInt32ToInt syserror))]
    | GenericOS_errorMsg VM heap _ =
      raise RE.UnexpectedPrimitiveArguments "GenericOS_errorMsg"

  fun GenericOS_syserror VM heap [nameAddress as Pointer _] =
      let
        val errorName = SLD.valueToString heap nameAddress
        val syserrorOpt =
            Option.map (Int o IntToSInt32) (OS.syserror errorName)
      in
        [SLD.optionToValue heap (syserrorOpt)]
      end
    | GenericOS_syserror VM heap _ =
      raise RE.UnexpectedPrimitiveArguments "GenericOS_syserror"

(*
GenericOS_fileOpen,"string * string -> word"
GenericOS_fileClose,"word -> unit"
GenericOS_fileRead,"word * int -> byteArray"
GenericOS_fileReadBuf,"word * byteArray * int * int -> int"
GenericOS_fileWrite,"word * byteArray * int * int -> int"
GenericOS_fileSetPosition,"word * int -> int"
GenericOS_fileGetPosition,"word -> int"
GenericOS_fileNo,"word -> int"
GenericOS_fileSize,"word -> int"
*)
  local
    datatype stream =
             TextInStream of TextIO.instream
           | BinInStream of BinIO.instream
           | TextOutStream of TextIO.outstream
           | BinOutStream of BinIO.outstream
    val STDIN_FILENO = 0w0 : UInt32
    val STDOUT_FILENO = 0w1 : UInt32
    val STDERR_FILENO = 0w2 : UInt32
    val streamMapRef =
        ref
            (List.foldr
                 (fn ((stream, fileNo), map) =>
                     IEnv.insert (map, UInt32ToInt fileNo, stream))
                 IEnv.empty
                 [
                   (TextInStream TextIO.stdIn, STDIN_FILENO),
                   (TextOutStream TextIO.stdOut, STDOUT_FILENO),
                   (TextOutStream TextIO.stdErr, STDERR_FILENO)
                 ])
    val nextFileNoRef = ref (0w3 : UInt32)
    fun addStream stream =
        let
          val fileno =
              !nextFileNoRef before nextFileNoRef := (!nextFileNoRef + 0w1)
        in
          streamMapRef
          := IEnv.insert (!streamMapRef, UInt32ToInt fileno, stream);
          fileno
        end
    fun getStreamOfFileNo fileNo =
        IEnv.find (!streamMapRef, UInt32ToInt fileNo)

    fun ioDescOfTextInStream stream =
        case TextIO.StreamIO.getReader (TextIO.getInstream stream) of
          (TextPrimIO.RD reader, _) => #ioDesc reader
    fun ioDescOfTextOutStream stream =
        case TextIO.StreamIO.getWriter (TextIO.getOutstream stream) of
          (TextPrimIO.WR writer, _) => #ioDesc writer
    fun ioDescOfBinInStream stream =
        case BinIO.StreamIO.getReader (BinIO.getInstream stream) of
          (BinPrimIO.RD reader, _) => #ioDesc reader
    fun ioDescOfBinOutStream stream =
        case BinIO.StreamIO.getWriter (BinIO.getOutstream stream) of
          (BinPrimIO.WR writer, _) => #ioDesc writer
    fun IODescOfStream stream =
        case stream of
          TextInStream stream => ioDescOfTextInStream stream
        | TextOutStream stream => ioDescOfTextOutStream stream
        | BinInStream stream => ioDescOfBinInStream stream
        | BinOutStream stream => ioDescOfBinOutStream stream
    fun IODescOfFileNo fileNo =
        let
          val ioDescOpt = 
              case getStreamOfFileNo fileNo of
                SOME(stream) => IODescOfStream stream
              | NONE => 
                raise RE.UnexpectedPrimitiveArguments "invalid fileNo"
        in
          ioDescOpt
        end
    fun fileNoOfIODesc IODesc =
        case
          List.find
              (fn (fileNo, stream) => IODescOfStream stream = SOME IODesc)
              (IEnv.listItemsi (!streamMapRef))
         of
          SOME(fileNo, _) => IntToSInt32 fileNo
        | NONE => raise RE.Error "fileNo of IODesc not found."

  in
  fun GenericOS_getSTDIN VM heap [_] = [Word STDIN_FILENO]
    | GenericOS_getSTDIN VM heap _ = 
      raise RE.UnexpectedPrimitiveArguments "GenericOS_getSTDIN"

  fun GenericOS_getSTDOUT VM heap [_] = [Word STDOUT_FILENO]
    | GenericOS_getSTDOUT VM heap _ = 
      raise RE.UnexpectedPrimitiveArguments "GenericOS_getSTDOUT"

  fun GenericOS_getSTDERR VM heap [_] = [Word STDERR_FILENO]
    | GenericOS_getSTDERR VM heap _ = 
      raise RE.UnexpectedPrimitiveArguments "GenericOS_getSTDERR"

  fun GenericOS_fileOpen VM heap [fileNameStringAddress, modeStringAddress] =
      let
        val fileName = SLD.valueToString heap fileNameStringAddress
        val mode = SLD.valueToString heap modeStringAddress
        val stream =
            case mode of
              "r" => TextInStream(TextIO.openIn fileName)
            | "rb" => BinInStream(BinIO.openIn fileName)
            | "w" => TextOutStream(TextIO.openOut fileName)
            | "wb" => BinOutStream(BinIO.openOut fileName)
            | "a" => TextOutStream(TextIO.openAppend fileName)
            | "ab" => BinOutStream(BinIO.openAppend fileName)
        val fileNo = addStream stream
      in
        [Word  fileNo]
      end
    | GenericOS_fileOpen VM heap _ = 
      raise RE.UnexpectedPrimitiveArguments "GenericOS_fileOpen"

  fun GenericOS_fileClose VM heap [Word fileNo] =
      (
        case getStreamOfFileNo fileNo of
          SOME(TextInStream stream) => TextIO.closeIn stream
        | SOME(BinInStream stream) => BinIO.closeIn stream
        | SOME(TextOutStream stream) => TextIO.closeOut stream
        | SOME(BinOutStream stream) => BinIO.closeOut stream
        | NONE =>
          raise
            RE.UnexpectedPrimitiveArguments
                "GenericOS_fileClose.fileClose: unknwon stream";
        [SLD.unitToValue heap ()]
      )
    | GenericOS_fileClose VM heap _ =
      raise RE.UnexpectedPrimitiveArguments "GenericOS_fileClose"

  fun GenericOS_fileRead VM heap [Word fileNo, Int bytes] =
      let
(*
        val _ = print ("fileRead: fileNo = " ^ UInt32.toString fileNo ^ ", bytes = " ^ SInt32.toString bytes ^ "\n")
*)
        val bytes = SInt32ToInt bytes
        val byteVector = 
            case getStreamOfFileNo fileNo of
              SOME(TextInStream stream) =>
              Byte.stringToBytes(TextIO.inputN (stream, bytes))
            | SOME(BinInStream stream) => BinIO.inputN (stream, bytes)
            | _ =>
              raise
                RE.UnexpectedPrimitiveArguments
                    "GenericOS_fileRead: invalid stream"
        val blockAddress =
            SLD.allocateStringBlockFromVector
                heap (byteVector, IntToUInt32 (Word8Vector.length byteVector))
      in
        [Pointer blockAddress]
      end
    | GenericOS_fileRead VM heap _ = 
      raise RE.UnexpectedPrimitiveArguments "GenericOS_fileRead"

  fun GenericOS_fileReadBuf
          VM heap [Word fileNo, Pointer arrayAddress, Int start, Int bytes] =
      let
        val bytes = SInt32ToInt bytes
        val byteVector =
            case getStreamOfFileNo fileNo of
              SOME(TextInStream stream) =>
              Byte.stringToBytes(TextIO.inputN (stream, bytes))
            | SOME(BinInStream stream) => BinIO.inputN (stream, bytes)
            | _ =>
              raise
                RE.UnexpectedPrimitiveArguments
                    "GenericOS_fileReadBuf: invalid stream"
        val byteVectorLength = Word8Vector.length byteVector
        val (byteArray, byteArrayLength) =
            SLD.expandStringBlock heap (Pointer arrayAddress)
      in
        Word8Array.copyVec
            {
              src = byteVector,
              si = 0,
              dst = byteArray,
              di = SInt32ToInt start,
              len = SOME(byteVectorLength)
            };
        [Int (IntToSInt32(byteVectorLength))]
      end
    | GenericOS_fileReadBuf VM heap _ = 
      raise RE.UnexpectedPrimitiveArguments "GenericOS_fileReadBuf"

  fun GenericOS_fileWrite 
          VM heap [Word fileNo, Pointer arrayAddress, Int start, Int bytes] =
      let
        val (byteArray, byteArrayLength) =
            SLD.expandStringBlock heap (Pointer arrayAddress)
        val string =
            Byte.unpackString
                (byteArray, SInt32ToInt start, SOME(SInt32ToInt bytes))
      in
(*
        print ("fileWrite: start = " ^ SInt32.toString start ^ ", bytes = " ^ SInt32.toString bytes ^ "\n");
*)
        case getStreamOfFileNo fileNo of
          SOME(TextOutStream stream) => TextIO.output (stream, string)
        | SOME(BinOutStream stream) =>
          BinIO.output (stream, Byte.stringToBytes string)
        | _ =>
          raise
            RE.UnexpectedPrimitiveArguments
                "GenericOS_fileWrite: invalid stream";
        [Int bytes]
      end
    | GenericOS_fileWrite VM heap _ = 
      raise RE.UnexpectedPrimitiveArguments "GenericOS_fileWrite"

  (* ToDo *)
  fun(* GenericOS_fileSetPosition VM heap [Word fileNo, Int newPos] =
    | *)GenericOS_fileSetPosition VM heap _ = 
      raise RE.UnexpectedPrimitiveArguments "GenericOS_fileSetPosition"

  (* ToDo *)
  fun GenericOS_fileGetPosition VM heap _ = 
      raise RE.UnexpectedPrimitiveArguments "GenericOS_fileGetPosition"

  fun GenericOS_fileNo VM heap [Word fileNo] = [Int (UInt32ToSInt32 fileNo)]
    | GenericOS_fileNo VM heap _ = 
      raise RE.UnexpectedPrimitiveArguments "GenericOS_fileNo"

  (* ToDo *)
  fun GenericOS_fileSize VM heap _ = 
      raise RE.UnexpectedPrimitiveArguments "GenericOS_fileSize"

  local
    fun isFDOfKind fileNo kind =
        case IODescOfFileNo fileNo of
          NONE => false
        | SOME desc => OS.IO.kind desc = kind
  in
  (* word -> bool *)
  fun GenericOS_isRegFD VM heap [Word fileNo] =
      [SLD.boolToValue heap (isFDOfKind fileNo OS.IO.Kind.file)]
    | GenericOS_isRegFD VM heap _ = 
      raise RE.UnexpectedPrimitiveArguments "GenericOS_isRegFD"

  (* word -> bool *)
  fun GenericOS_isDirFD VM heap [Word fileNo] =
      [SLD.boolToValue heap (isFDOfKind fileNo OS.IO.Kind.dir)]
    | GenericOS_isDirFD VM heap _ = 
      raise RE.UnexpectedPrimitiveArguments "GenericOS_isDirFD"

  (* word -> bool *)
  fun GenericOS_isChrFD VM heap [Word fileNo] =
      [SLD.boolToValue heap (isFDOfKind fileNo OS.IO.Kind.device)]
    | GenericOS_isChrFD VM heap _ = 
      raise RE.UnexpectedPrimitiveArguments "GenericOS_isChrFD"

  (* word -> bool *)
  fun GenericOS_isBlkFD VM heap [Word fileNo] =
      [SLD.boolToValue heap (isFDOfKind fileNo OS.IO.Kind.device)]
    | GenericOS_isBlkFD VM heap _ = 
      raise RE.UnexpectedPrimitiveArguments "GenericOS_isBlkFD"

  (* word -> bool *)
  fun GenericOS_isLinkFD VM heap [Word fileNo] =
      [SLD.boolToValue heap (isFDOfKind fileNo OS.IO.Kind.symlink)]
    | GenericOS_isLinkFD VM heap _ = 
      raise RE.UnexpectedPrimitiveArguments "GenericOS_isLinkFD"

  (* word -> bool *)
  fun GenericOS_isFIFOFD VM heap [Word fileNo] =
      [SLD.boolToValue heap (isFDOfKind fileNo OS.IO.Kind.pipe)]
    | GenericOS_isFIFOFD VM heap _ = 
      raise RE.UnexpectedPrimitiveArguments "GenericOS_isFIFOFD"

  (* word -> bool *)
  fun GenericOS_isSockFD VM heap [Word fileNo] =
      [SLD.boolToValue heap (isFDOfKind fileNo OS.IO.Kind.socket)]
    | GenericOS_isSockFD VM heap _ = 
      raise RE.UnexpectedPrimitiveArguments "GenericOS_isSockFD"

  local
    (* this bitmap value is shared with Basis OS_IO.sml. *)
    val [rdBit, wrBit, prBit] = [0w1 : UInt32, 0w2, 0w4]
    fun setPollDesc bit pollDesc =
        List.foldr
            (fn ((testBit, f), pollDesc) =>
                if UInt32.andb (testBit, bit) <> 0w0
                then f pollDesc
                else pollDesc)
            pollDesc
            [
              (rdBit, OS.IO.pollIn),
              (wrBit, OS.IO.pollOut),
              (prBit, OS.IO.pollPri)
            ]
    fun getBitOfPollInfo pollInfo =
        List.foldr
            (fn ((testBit, f), bit) =>
                if f pollInfo then UInt32.orb (testBit, bit) else bit)
            0w0
            [
              (rdBit, OS.IO.isIn),
              (wrBit, OS.IO.isOut),
              (prBit, OS.IO.isPri)
            ]
    (* pollDesc is represented as (int * word).
     * int is a fileNo, word is a bitmap. *)
    fun valueToPollDesc heap (Pointer tupleBlock) =
        let
          val [Int desc, Word bit] = H.getFields heap (tupleBlock, 0w0, 0w2)
          val ioDescOpt = IODescOfFileNo (SInt32ToUInt32 desc)
          val pollDescOpt =
              case ioDescOpt of
                SOME ioDesc => OS.IO.pollDesc ioDesc
              | NONE => NONE (* ? *)
        in
          case pollDescOpt of
            SOME pollDesc => setPollDesc bit pollDesc
          | NONE => raise RE.Error "poll is not supported."
        end
      | valueToPollDesc heap value =
        raise RE.Error "valueToPollDesc expects a pointer."
    fun pollInfoToValue heap pollInfo =
        let
          val ioDesc = OS.IO.pollToIODesc(OS.IO.infoToPollDesc pollInfo)
          val fileNo = fileNoOfIODesc ioDesc
          val bit = getBitOfPollInfo pollInfo
          val block = SLD.tupleElementsToValue heap 0w0 [Int fileNo, Word bit]
        in
          block
        end
  in
  (* ((int * word) list * (int * int) option) -> (int * word) list
   * 
   *)
  fun GenericOS_poll
          VM
          heap
          [pollDescListAddress as Pointer _, timeOutOptAddress as Pointer _] =
      let
        val pollDescBlocks = SLD.valueToList heap pollDescListAddress
        val pollDescs = map (valueToPollDesc heap) pollDescBlocks
        val timeOutBlockOpt = SLD.valueToOption heap timeOutOptAddress
        val timeOutOpt =
            case timeOutBlockOpt of
              NONE => NONE
            | SOME block =>
              case SLD.valueToTupleElements heap block of
                [Int sec, Int usec] => SOME(Time.fromSeconds sec)
        val pollInfos = OS.IO.poll (pollDescs, timeOutOpt)
        val pollInfosValue =
            SLD.listToValue heap (pollInfoToValue heap) pollInfos
      in
        [pollInfosValue]
      end
    | GenericOS_poll VM heap _ = 
      raise RE.UnexpectedPrimitiveArguments "GenericOS_poll"

  (* int -> word *)
  fun GenericOS_getPOLLINFlag VM heap [_] = [Word rdBit]
    | GenericOS_getPOLLINFlag VM heap _ = 
      raise RE.UnexpectedPrimitiveArguments "GenericOS_getPOLLINFlag"

  (* int -> word *)
  fun GenericOS_getPOLLOUTFlag VM heap [_] = [Word wrBit]
    | GenericOS_getPOLLOUTFlag VM heap _ = 
      raise RE.UnexpectedPrimitiveArguments "GenericOS_getPOLLOUTFlag"

  (* int -> word *)
  fun GenericOS_getPOLLPRIFlag VM heap [_] = [Word prBit]
    | GenericOS_getPOLLPRIFlag VM heap _ = 
      raise RE.UnexpectedPrimitiveArguments "GenericOS_getPOLLPRIFlag"

  end (* local *)

  end (* local *)

  end (* local *)

  (********************)

  fun GenericOS_system VM heap [commandStringAddress as Pointer _] =
      let
        val commandString = SLD.valueToString heap commandStringAddress
        val status = OS.Process.system commandString
        val statusInt =
            if status = OS.Process.success
            then C.OS_Process_success
            else C.OS_Process_failure
      in
        [Int (IntToSInt32 statusInt)]
      end
    | GenericOS_system VM heap _ =
      raise RE.UnexpectedPrimitiveArguments "GenericOS_system"

  fun GenericOS_exit VM heap [Int exitCode] =
      let
        val exitCodeStatus =
            if exitCode = 0 then OS.Process.success else OS.Process.failure
      in
        OS.Process.exit exitCodeStatus;
        [SLD.unitToValue heap ()]
      end
    | GenericOS_exit VM heap _ = 
      raise RE.UnexpectedPrimitiveArguments "GenericOS_exit"

  fun GenericOS_getEnv VM heap [nameStringAddress as Pointer _] = 
      let
        val nameString = SLD.valueToString heap nameStringAddress
        val valueOpt = OS.Process.getEnv nameString
      in
        case valueOpt of
          NONE => [SLD.optionToValue heap NONE]
        | SOME value =>
          let val value = SLD.stringToValue heap value
          in [SLD.optionToValue heap (SOME value)]
          end
      end
    | GenericOS_getEnv VM heap _ = 
      raise RE.UnexpectedPrimitiveArguments "GenericOS_getEnv"

  fun GenericOS_sleep VM heap [Word seconds] =
      raise RE.InvalidCode "Sorry, OS_sleep is not implemented"
    | GenericOS_sleep VM heap _ = 
      raise RE.UnexpectedPrimitiveArguments "GenericOS_sleep"

  (********************)

  local
    val streamMapRef = ref (IEnv.empty : OS.FileSys.dirstream IEnv.map)
    val nextDirNoRef = ref (0w0 : UInt32)
    fun addStream stream =
        let
          val dirno =
              !nextDirNoRef before nextDirNoRef := (!nextDirNoRef + 0w1)
        in
          streamMapRef
          := IEnv.insert (!streamMapRef, UInt32ToInt dirno, stream);
          dirno
        end
    fun getStreamOfDirNo dirNo =
        case IEnv.find (!streamMapRef, UInt32ToInt dirNo) of
          SOME stream => stream
        | NONE => 
          raise
            RE.UnexpectedPrimitiveArguments
                "getStreamOfDirNo: unknwon stream";
  in
  (* string  -> word *)
  fun GenericOS_openDir VM heap [dirNameAddress as Pointer _] =
      let
        val dirName = SLD.valueToString heap dirNameAddress
        val stream = OF.openDir dirName
        val dirNo = addStream stream
      in [Word dirNo]
      end
    | GenericOS_openDir VM heap _ =
      raise RE.UnexpectedPrimitiveArguments "GenericOS_openDir"

  (* word  -> string option *)
  fun GenericOS_readDir VM heap [Word dirNo] =
      let val stream = getStreamOfDirNo dirNo
      in
        case OF.readDir stream of
          "" => [SLD.optionToValue heap NONE]
        | value =>
          let val value = SLD.stringToValue heap value
          in [SLD.optionToValue heap (SOME value)]
          end
      end
    | GenericOS_readDir VM heap _ =
      raise RE.UnexpectedPrimitiveArguments "GenericOS_readDir"

  (* word  -> unit *)
  fun GenericOS_rewindDir VM heap [Word dirNo] =
      let val stream = getStreamOfDirNo dirNo
      in OF.rewindDir stream; [SLD.unitToValue heap ()] end
    | GenericOS_rewindDir VM heap _ =
      raise RE.UnexpectedPrimitiveArguments "GenericOS_rewindDir"

  (* word  -> unit *)
  fun GenericOS_closeDir VM heap [Word dirNo] =
      let val stream = getStreamOfDirNo dirNo
      in OF.closeDir stream; [SLD.unitToValue heap ()] end
    | GenericOS_closeDir VM heap _ =
      raise RE.UnexpectedPrimitiveArguments "GenericOS_closeDir"

  end (* local *)

  (* string -> unit *)
  fun GenericOS_chDir VM heap [dirNameAddress as Pointer _] =
      let
        val dirName = SLD.valueToString heap dirNameAddress
        val _ = OF.chDir dirName
      in
        [SLD.unitToValue heap ()]
      end
    | GenericOS_chDir VM heap _ =
      raise RE.UnexpectedPrimitiveArguments "GenericOS_chDir"

  (* int  -> string *)
  fun GenericOS_getDir VM heap [Int _] =
      let
        val dirName = OF.getDir ()
        val value = SLD.stringToValue heap dirName
      in [value]
      end
    | GenericOS_getDir VM heap _ =
      raise RE.UnexpectedPrimitiveArguments "GenericOS_getDir"

  (* string  -> unit *)
  fun GenericOS_mkDir VM heap [dirNameAddress as Pointer _] =
      let
        val dirName = SLD.valueToString heap dirNameAddress
        val _ = OF.mkDir dirName
      in [SLD.unitToValue heap ()]
      end
    | GenericOS_mkDir VM heap _ =
      raise RE.UnexpectedPrimitiveArguments "GenericOS_mkDir"

  (* string  -> unit *)
  fun GenericOS_rmDir VM heap [dirNameAddress as Pointer _ ] =
      let
        val dirName = SLD.valueToString heap dirNameAddress
        val _ = OF.rmDir dirName
      in [SLD.unitToValue heap ()]
      end
    | GenericOS_rmDir VM heap _ =
      raise RE.UnexpectedPrimitiveArguments "GenericOS_rmDir"

  (* string  -> bool *)
  fun GenericOS_isDir VM heap [dirNameAddress as Pointer _] =
      let val dirName = SLD.valueToString heap dirNameAddress
      in [SLD.boolToValue heap (OF.isDir dirName)]
      end
    | GenericOS_isDir VM heap _ =
      raise RE.UnexpectedPrimitiveArguments "GenericOS_isDir"

  (* string  -> bool *)
  fun GenericOS_isLink VM heap [nameAddress as Pointer _] =
      let val name = SLD.valueToString heap nameAddress
      in [SLD.boolToValue heap (OF.isLink name)]
      end
    | GenericOS_isLink VM heap _ =
      raise RE.UnexpectedPrimitiveArguments "GenericOS_isLink"

  (* string  -> string *)
  fun GenericOS_readLink VM heap [nameAddress as Pointer _] =
      let
        val name = SLD.valueToString heap nameAddress
        val target = OF.readLink name
      in [SLD.stringToValue heap target]
      end
    | GenericOS_readLink VM heap _ =
      raise RE.UnexpectedPrimitiveArguments "GenericOS_readLink"

  (* string  -> int *)
  fun GenericOS_getFileModTime VM heap [nameAddress as Pointer _] =
      let
        val name = SLD.valueToString heap nameAddress
        val time = OF.modTime name
        val seconds = Time.toSeconds time
      in [Int(seconds)]
      end
    | GenericOS_getFileModTime VM heap _ =
      raise RE.UnexpectedPrimitiveArguments "GenericOS_getFileModTime"

  (* string * int  -> unit *)
  fun GenericOS_setFileTime VM heap [nameAddress as Pointer _, Int seconds] =
      let
        val name = SLD.valueToString heap nameAddress
        val time = Time.fromSeconds seconds
        val _ = OF.setTime (name, SOME time)
      in [SLD.unitToValue heap ()]
      end
    | GenericOS_setFileTime VM heap _ =
      raise RE.UnexpectedPrimitiveArguments "GenericOS_setFileTime"

  (* string  -> int *)
  fun GenericOS_getFileSize VM heap [nameAddress as Pointer _] =
      let
        val name = SLD.valueToString heap nameAddress
        val fileSize = OF.fileSize name
      in [Int(IntToSInt32 fileSize)]
      end
    | GenericOS_getFileSize VM heap _ =
      raise RE.UnexpectedPrimitiveArguments "GenericOS_getFileSize"

  (* string  -> unit *)
  fun GenericOS_remove VM heap [nameAddress as Pointer _] =
      let
        val name = SLD.valueToString heap nameAddress
        val _ = OF.remove name
      in [SLD.unitToValue heap ()]
      end
    | GenericOS_remove VM heap _ =
      raise RE.UnexpectedPrimitiveArguments "GenericOS_remove"

  (* string * string  -> unit *)
  fun GenericOS_rename
          VM heap [oldNameAddress as Pointer _, newNameAddress as Pointer _] =
      let
        val oldName = SLD.valueToString heap oldNameAddress
        val newName = SLD.valueToString heap newNameAddress
        val _ = OF.rename {old = oldName, new = newName}
      in [SLD.unitToValue heap ()]
      end
    | GenericOS_rename VM heap _ =
      raise RE.UnexpectedPrimitiveArguments "GenericOS_rename"

  (* string  -> bool *)
  fun GenericOS_isFileExists VM heap [nameAddress as Pointer _] =
      let val name = SLD.valueToString heap nameAddress
      in [SLD.boolToValue heap (OF.access (name, []))]
      end
    | GenericOS_isFileExists VM heap _ =
      raise RE.UnexpectedPrimitiveArguments "GenericOS_isFileExists"

  (* string  -> bool *)
  fun GenericOS_isFileReadable VM heap [nameAddress as Pointer _] =
      let val name = SLD.valueToString heap nameAddress
      in [SLD.boolToValue heap (OF.access (name, [OF.A_READ]))]
      end
    | GenericOS_isFileReadable VM heap _ =
      raise RE.UnexpectedPrimitiveArguments "GenericOS_isFileReadable"

  (* string  -> bool *)
  fun GenericOS_isFileWritable VM heap [nameAddress as Pointer _] =
      let val name = SLD.valueToString heap nameAddress
      in [SLD.boolToValue heap (OF.access (name, [OF.A_WRITE]))]
      end
    | GenericOS_isFileWritable VM heap _ =
      raise RE.UnexpectedPrimitiveArguments "GenericOS_isFileWritable"

  (* string  -> bool *)
  fun GenericOS_isFileExecutable VM heap [nameAddress as Pointer _] =
      let val name = SLD.valueToString heap nameAddress
      in [SLD.boolToValue heap (OF.access (name, [OF.A_EXEC]))]
      end
    | GenericOS_isFileExecutable VM heap _ =
      raise RE.UnexpectedPrimitiveArguments "GenericOS_isFileExecutable"

  (* unit  -> string *)
  fun GenericOS_tempFileName VM heap [Int _] =
      let
        val name = OF.tmpName ()
        val value = SLD.stringToValue heap name
      in [value]
      end
    | GenericOS_tempFileName VM heap _ =
      raise RE.UnexpectedPrimitiveArguments "GenericOS_tempFileName"

  (* string  -> word *)
  fun GenericOS_getFileID VM heap [nameAddress as Pointer _] =
      let val name = SLD.valueToString heap nameAddress
      in [Word (WordToUInt32(OF.hash (OF.fileId name)))]
      end
    | GenericOS_getFileID VM heap _ =
      raise RE.UnexpectedPrimitiveArguments "GenericOS_getFileID"

  (********************)

  fun syserrOfExn exn =
      case exn of
        OS.SysErr(_, syserrorOpt) => syserrorOpt
      | IO.Io{cause, ...} => syserrOfExn cause
      | _ => NONE
  fun handlePrimitiveException heap exn =
      let
        val message = 
            case exn of
              OS.SysErr(message, syserrorOpt) => message 
            | IO.Io {name, function, cause} => exnMessage cause
            | exn => raise exn
        val syserrorOpt = syserrOfExn exn
        val exnValue = SLD.exnToValue heap (OS.SysErr(message, syserrorOpt))
      in
        raise VM.PrimitiveException exnValue
      end

  (********************)

  val primitives =
      [
        {name = "GenericOS_errorName", function = GenericOS_errorName},
        {name = "GenericOS_errorMsg", function = GenericOS_errorMsg},
        {name = "GenericOS_syserror", function = GenericOS_syserror},
        {name = "GenericOS_getSTDIN", function = GenericOS_getSTDIN},
        {name = "GenericOS_getSTDOUT", function = GenericOS_getSTDOUT},
        {name = "GenericOS_getSTDERR", function = GenericOS_getSTDERR},
        {name = "GenericOS_fileOpen", function = GenericOS_fileOpen},
        {name = "GenericOS_fileClose", function = GenericOS_fileClose},
        {name = "GenericOS_fileRead", function = GenericOS_fileRead},
        {name = "GenericOS_fileReadBuf", function = GenericOS_fileReadBuf},
        {name = "GenericOS_fileWrite", function = GenericOS_fileWrite},
        {
          name = "GenericOS_fileSetPosition",
          function = GenericOS_fileSetPosition
        },
        {
          name = "GenericOS_fileGetPosition",
          function = GenericOS_fileGetPosition
        },
        {name = "GenericOS_fileNo", function = GenericOS_fileNo},
        {name = "GenericOS_fileSize", function = GenericOS_fileSize},
        {name = "GenericOS_system", function = GenericOS_system},
        {name = "GenericOS_exit", function = GenericOS_exit},
        {name = "GenericOS_getEnv", function = GenericOS_getEnv},
        {name = "GenericOS_sleep", function = GenericOS_sleep},
        {name = "GenericOS_openDir", function = GenericOS_openDir},
        {name = "GenericOS_readDir", function = GenericOS_readDir},
        {name = "GenericOS_rewindDir", function = GenericOS_rewindDir},
        {name = "GenericOS_closeDir", function = GenericOS_closeDir},
        {name = "GenericOS_chDir", function = GenericOS_chDir},
        {name = "GenericOS_getDir", function = GenericOS_getDir},
        {name = "GenericOS_mkDir", function = GenericOS_mkDir},
        {name = "GenericOS_rmDir", function = GenericOS_rmDir},
        {name = "GenericOS_isDir", function = GenericOS_isDir},
        {name = "GenericOS_isLink", function = GenericOS_isLink},
        {name = "GenericOS_readLink", function = GenericOS_readLink},
        {
          name = "GenericOS_getFileModTime",
          function = GenericOS_getFileModTime
        },
        {name = "GenericOS_setFileTime", function = GenericOS_setFileTime},
        {name = "GenericOS_getFileSize", function = GenericOS_getFileSize},
        {name = "GenericOS_remove", function = GenericOS_remove},
        {name = "GenericOS_rename", function = GenericOS_rename},
        {name = "GenericOS_isFileExists", function = GenericOS_isFileExists},
        {
          name = "GenericOS_isFileReadable",
          function = GenericOS_isFileReadable
        },
        {
          name = "GenericOS_isFileWritable",
          function = GenericOS_isFileWritable
        },
        {
          name = "GenericOS_isFileExecutable",
          function = GenericOS_isFileExecutable
        },
        {name = "GenericOS_tempFileName", function = GenericOS_tempFileName},
        {name = "GenericOS_getFileID", function = GenericOS_getFileID},
        {name = "GenericOS_isRegFD", function = GenericOS_isRegFD},
        {name = "GenericOS_isDirFD", function = GenericOS_isDirFD},
        {name = "GenericOS_isChrFD", function = GenericOS_isChrFD},
        {name = "GenericOS_isBlkFD", function = GenericOS_isBlkFD},
        {name = "GenericOS_isLinkFD", function = GenericOS_isLinkFD},
        {name = "GenericOS_isFIFOFD", function = GenericOS_isFIFOFD},
        {name = "GenericOS_isSockFD", function = GenericOS_isSockFD},
        {name = "GenericOS_poll", function = GenericOS_poll},
        {name = "GenericOS_getPOLLINFlag", function = GenericOS_getPOLLINFlag},
        {
          name = "GenericOS_getPOLLOUTFlag",
          function = GenericOS_getPOLLOUTFlag
        },
        {
          name = "GenericOS_getPOLLPRIFlag",
          function = GenericOS_getPOLLPRIFlag
        }
      ]

  val primitives =
      map
          (fn {name, function} =>
              {
                name = name,
                function =
                fn (VM : VM.VM) =>
                   fn heap =>
                      fn arg =>
                         (function VM heap arg)
                         handle exn => handlePrimitiveException heap exn
              })
          primitives

  (***************************************************************************)

end;
