(**
 * 
 * @author YAMATODANI Kiyoshi
 * @version $Id: BenchmarkRunner.sml,v 1.13 2006/02/02 12:59:18 kiyoshiy Exp $
 *)
functor BenchmarkRunner(RuntimeRunner : RUNTIME_RUNNER) : BENCHMARK_RUNNER =
struct

  (***************************************************************************)

  structure BT = BenchmarkTypes
  structure CU = ChannelUtility
  structure PU = PathUtility
  structure U = Utility

  (***************************************************************************)

  fun compile
      {
        preludesFileName,
        preludesChannel,
        sourceFileName,
        sourceChannel,
        outputChannel,
        executableChannel
      } =
      let
        val session =
            StandAloneSession.openSession {outputChannel = executableChannel}
      in
        let
          val _ = print ("begin compile: " ^ sourceFileName ^ "\n")
          val _ = Control.printBinds := false
          val _ = Control.printWarning := false
          val _ = Control.checkType := false
          val _ = Control.generateExnHistory := true
          val context =
              Top.initialize
              {
                session = session,
                standardOutput = outputChannel, (* no output expected. *)
                standardError = outputChannel,
                loadPathList = ["."],
                getVariable = OS.Process.getEnv
              }
          val _ =
              if
                Top.run
                  context
                  {
                    interactionMode = Top.NonInteractive {stopOnError = true},
                    initialSource = preludesChannel,
                    initialSourceName = preludesFileName,
                    getBaseDirectory = fn () => U.getDirectory preludesFileName
                  }
              then ()
              else raise Fail "cannot compile prelude."
          val compileTimer = ProcessTimer.createTimer ()
          val _ = 
              if
                Top.run
                  context
                  {
                    interactionMode = Top.NonInteractive {stopOnError = true},
                    initialSource = sourceChannel,
                    initialSourceName = sourceFileName,
                    getBaseDirectory = fn () => U.getDirectory sourceFileName
                  }
              then ()
              else raise Fail "cannot compile benchmark."
          val compileTime = ProcessTimer.getTime compileTimer
          val _ = print ("end compile: " ^ sourceFileName ^ "\n")
        in
          #close session ();
          compileTime
        end
          handle exn => (#close session (); print "compile error\n"; raise exn)
      end

  fun execute {executableFileName, outputChannel} =
      let
          val _ = print ("begin execute: " ^ executableFileName ^ "\n")
          val executionTimer = ProcessTimer.createTimer ()
          val status =
              RuntimeRunner.execute
                  {
                    executableFileName = executableFileName,
                    outputChannel = outputChannel
                  }
          val executionTime = ProcessTimer.getTime executionTimer
          val _ = print ("end execute: " ^ executableFileName ^ "\n")
      in
        (executionTime, status)
      end

  fun runBenchmark
      {
        preludesFileName,
        preludesChannel,
        sourceFileName,
        sourceChannel,
        compileOutputChannel,
        executeOutputChannel
      } =
      let
        val executableFileName = U.replaceExt "imo" sourceFileName
        val compileTime =
            U.finally
                (FileChannel.openOut {fileName = executableFileName})
                (fn executableChannel =>
                    compile
                        {
                          preludesFileName = preludesFileName,
                          preludesChannel = preludesChannel,
                          sourceFileName = sourceFileName,
                          sourceChannel = sourceChannel,
                          outputChannel = compileOutputChannel,
                          executableChannel = executableChannel
                        })
                U.closeOutputChannel
        val (executionTime, exitStatus) = 
            execute
                {
                  executableFileName = executableFileName,
                  outputChannel = executeOutputChannel
                }
      in
        {
          compileTime = compileTime,
          executionTime = executionTime,
          exitStatus = exitStatus
        }
      end

  (***************************************************************************)

end