(**
 * 
 * @author YAMATODANI Kiyoshi
 * @version $Id: TestDriver.sml,v 1.19 2007/09/20 09:05:53 matsu Exp $
 *)
functor TestDriver(
                    structure TestCaseRunner : TEST_CASE_RUNNER
                    structure Printer : RESULT_PRINTER
                  )
        : TEST_DRIVER =
struct

  (***************************************************************************)

  structure CU = ChannelUtility
  structure PU = PathUtility
  structure TT = TestTypes

  (***************************************************************************)

  (** ensure finalizer is executed *)
  fun finally arg userFunction finalizer =
      ((userFunction arg) before (finalizer arg))
      handle e => (finalizer arg; raise e)

  fun zip3 (lefts, mids, rights) =
      let
        fun collect ([], [], []) results = List.rev results
          | collect
                (left :: lefts, mid :: mids, right :: rights) results =
            collect (lefts, mids, rights) ((left, mid, right) :: results)
          | collect _ _ = raise Fail "zip3: unequal length"
      in
        collect (lefts, mids, rights) []
      end

  fun skipWS (channel : ChannelTypes.InputChannel) =
      if #isEOF channel ()
      then NONE
      else 
        case #receive channel () of
          SOME byte =>
          if Char.isSpace(Char.chr(Word8.toInt byte))
          then skipWS channel
          else SOME byte
        | NONE => NONE

  fun compareChannelContents
      (left : ChannelTypes.InputChannel, right : ChannelTypes.InputChannel) =
      case (skipWS left, skipWS right) of
        (SOME leftByte, SOME rightByte) =>
        if leftByte = rightByte
        then compareChannelContents (left, right)
        else false
      | (NONE, NONE) => true
      | _ => false

  fun closeOutputChannel (channel : ChannelTypes.OutputChannel) =
      #close channel ()

  fun closeInputChannel (channel : ChannelTypes.InputChannel) =
      #close channel ()

  (****************************************)

  fun runOneCase (preludePath, isCompiledPrelude, sourcePath, expectedPath) =
      let
        val sourceVector =
            finally
                (FileChannel.openIn {fileName = sourcePath})
                CU.getAll
                closeInputChannel
        val expectedVector =
            finally
                (FileChannel.openIn {fileName = expectedPath})
                CU.getAll
                closeInputChannel
        val resultArrayOptRef = ref (SOME (Word8Array.fromList []))
        val exceptionsRef = ref ([] : exn list)

        val _ = 
            (finally
             (FileChannel.openIn {fileName = sourcePath})
             (fn sourceChannel =>
                 finally
                 (ByteArrayChannel.openOut {buffer = resultArrayOptRef})
                 (fn resultChannel =>
                     finally
                     (FileChannel.openIn {fileName = preludePath})
                     (fn preludeChannel =>
                         TestCaseRunner.runCase
                         {
                           preludeFileName = preludePath,
                           preludeChannel = preludeChannel,
                           isCompiledPrelude = isCompiledPrelude,
                           sourceFileName = sourcePath,
                           sourceChannel = sourceChannel,
                           resultChannel = resultChannel
                         })
                     closeInputChannel)
                 closeOutputChannel)
             closeInputChannel)
(*
            handle error =>  raise error
*)
            handle error => exceptionsRef := (error :: (!exceptionsRef))

        val resultArray = valOf(!resultArrayOptRef)

        (* ToDo : comparison should be done in ResultPrinter, not here ?? *)
        val isSameContents =
            finally
            (ByteArrayChannel.openIn {buffer = resultArray})
            (fn resultChannel =>
                finally
                (ByteVectorChannel.openIn {buffer = expectedVector})
                (fn expectedChannel =>
                    compareChannelContents (resultChannel, expectedChannel))
                closeInputChannel)
            closeInputChannel
      in
        {
          sourcePath = sourcePath,
          isSameContents = isSameContents,
          source = sourceVector,
          output = Word8ArraySlice.vector (Word8ArraySlice.slice (resultArray, 0, NONE)),
          expected = expectedVector,
          exceptions = ! exceptionsRef
        } : TT.caseResult
      end

  fun isSourceFile fileName =
      case PU.splitBaseExt fileName of
        {ext = SOME "sml", ...} => true | _ => false

  fun collectSourcePathNamePairs sourcePath =
      let
        val (sourceDirectory, sourceNames) =
            if OS.FileSys.isDir sourcePath
            then (* files in dir *)
              let
                val sourceNames = PU.collectFilesInDir isSourceFile sourcePath
                val map =
                    foldr
                        (fn (name, map) => SEnv.insert (map, name, name))
                        SEnv.empty
                        sourceNames
                val sortedSourceNames = SEnv.listItems map
              in
                (sourcePath, sortedSourceNames)
              end
            else
              (* single file. *)
              if isSourceFile sourcePath
              then
                let val {dir, file} = PU.splitDirFile sourcePath
                in (dir, [file]) end
              else raise Fail ("not directory nor .sml file:" ^ sourcePath)
      in
        map
            (fn sourceName => {dir = sourceDirectory, file = sourceName})
            sourceNames
      end

  fun runTests
          {
            prelude,
            isCompiledPrelude,
            sourcePaths,
            expectedDirectory,
            resultDirectory
          } =
      let
val _ = print ("prelude = [" ^ prelude ^ "]\n")
val _ = print ("isCompildePrelude = [" ^ Bool.toString isCompiledPrelude ^ "]\n")
        val printerContext = Printer.initialize {directory = resultDirectory}
        val messagesRef = ref ([] : string list)
        fun replaceExt ext fileName =
            case PU.splitBaseExt fileName of
              {base, ...} => PU.joinBaseExt{base = base, ext = SOME ext}
        val sourceDirNames =
            List.concat(map collectSourcePathNamePairs sourcePaths)
        val (printerContext, resultOptsRev) = 
            foldl
            (fn (sourceDirFile as {file, ...}, (printerContext, resultOpts)) =>
                let
                  val sourcePath = PU.joinDirFile sourceDirFile
                  val expectedPath = 
                      PU.joinDirFile
                      {dir = expectedDirectory, file = replaceExt "out" file}
                  val result =
                      runOneCase
                        (prelude, isCompiledPrelude, sourcePath, expectedPath)
                  val printerContext = Printer.printCase printerContext result
                in
                  (printerContext, SOME result :: resultOpts)
                end
                handle
                error as IO.Io _ =>
                (
                  messagesRef := (exnMessage error) :: (!messagesRef);
                  (printerContext, NONE :: resultOpts)
                ))
            (printerContext, [])
            sourceDirNames
        val results =
            List.rev(List.map valOf (List.filter isSome resultOptsRev))
      in
        Printer.printSummary
            printerContext
            {
              messages = List.rev (!messagesRef),
              results = results
            };
        Printer.finalize printerContext
      end

  (***************************************************************************)

end

