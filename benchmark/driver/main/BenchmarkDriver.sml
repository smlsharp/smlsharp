(**
 * 
 * @author YAMATODANI Kiyoshi
 * @version $Id: BenchmarkDriver.sml,v 1.7 2007/01/26 09:33:15 kiyoshiy Exp $
 *)
functor BenchmarkDriver(
                         structure BenchmarkRunner : BENCHMARK_RUNNER
                         structure Printer : RESULT_PRINTER
                       )
        : BENCHMARK_DRIVER =
struct

  (***************************************************************************)

  structure BT = BenchmarkTypes
  structure PU = PathUtility
  structure U = Utility

  (***************************************************************************)

  fun runOneCase (preludePath, isCompiledPrelude, sourcePath) = 
      let
        val compileOutputArrayOptRef = ref (SOME (Word8Array.fromList []))
        val executeOutputArrayOptRef = ref (SOME (Word8Array.fromList []))
        val exceptionsRef = ref ([] : exn list)
        val compileOutputChannel =
            ByteArrayChannel.openOut {buffer = compileOutputArrayOptRef}
        val executeOutputChannel =
            ByteArrayChannel.openOut {buffer = executeOutputArrayOptRef}

        val {compileTime, compileProfile, executionTime, exitStatus} = 
            (U.finally
                 (FileChannel.openIn {fileName = sourcePath})
                 (fn sourceChannel =>
                     U.finally
                         (FileChannel.openIn {fileName = preludePath})
                         (fn preludeChannel =>
                             BenchmarkRunner.runBenchmark
                             {
                               preludeFileName = preludePath,
                               preludeChannel = preludeChannel,
                               isCompiledPrelude = isCompiledPrelude,
                               sourceFileName = sourcePath,
                               sourceChannel = sourceChannel,
                               compileOutputChannel = compileOutputChannel,
                               executeOutputChannel = executeOutputChannel
                             })
                         U.closeInputChannel)
                 U.closeInputChannel)
            handle error =>
                   (
                     exceptionsRef := (error :: (!exceptionsRef));
                     {
                       compileTime = BT.zeroElapsedTime,
                       compileProfile = nil,
                       executionTime = BT.zeroElapsedTime,
                       exitStatus = OS.Process.failure
                     }
                   )

      in
        #close compileOutputChannel();
        #close executeOutputChannel();

        {
          sourcePath = sourcePath,
          compileTime = compileTime,
          compileProfile = compileProfile,
          executionTime = executionTime,
          exitStatus = exitStatus,
          exceptions = exceptionsRef,
          compileOutputArrayOpt = !compileOutputArrayOptRef,
          executeOutputArrayOpt = !executeOutputArrayOptRef
        } : BT.benchmarkResult
      end

  fun isSourceFile fileName =
      case PU.splitBaseExt fileName of
        {ext = SOME "sml", ...} => true | _ => false

  fun collectSourcePathNamePairs sourcePath =
      let
        val (sourceDirectory, sourceNames) =
            if OS.FileSys.isDir sourcePath
            then (* files in dir *)
              (sourcePath, PU.collectFilesInDir isSourceFile sourcePath)
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

  fun runBenchmarks
          {prelude, isCompiledPrelude, sourcePaths, resultDirectory} =
      let
        val printerContext = Printer.initialize {directory = resultDirectory}
        val messagesRef = ref ([] : string list)
        val sourceDirNames =
            List.concat(map collectSourcePathNamePairs sourcePaths)
        val (printerContext, resultOptsRev) = 
            foldl
            (fn (sourceDirFile as {file, ...}, (printerContext, resultOpts)) =>
                let
                  val sourcePath = PU.joinDirFile sourceDirFile
                  val result =
                      runOneCase(prelude, isCompiledPrelude, sourcePath)
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
            {messages = List.rev (!messagesRef), results = results};
        Printer.finalize printerContext
      end

  (***************************************************************************)

end

