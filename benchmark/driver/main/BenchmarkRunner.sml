(**
 * 
 * @author YAMATODANI Kiyoshi
 * @version $Id: BenchmarkRunner.sml,v 1.21 2008/03/11 08:53:54 katsu Exp $
 *)
functor BenchmarkRunner(RuntimeRunner : RUNTIME_RUNNER) : BENCHMARK_RUNNER =
struct

  (***************************************************************************)

  structure BT = BenchmarkTypes
  structure CU = ChannelUtility
  structure PU = PathUtility
  structure U = Utility

  (***************************************************************************)

  fun compilePrelude
          (parameter : Top.sysParam) preludePath preludeChannel = 
      let
(*
        val (context, compileUnitStamp) = Top.initialize ()
*)
        val (context, compileUnitStamp) =
            Top.initializeContextAndCompileUnitStamp ()
        val preludeDir = U.getDirectory preludePath

        val currentSwitchTrace = !Control.switchTrace
        val currentPrintBinds = !Control.printBinds

        val _ = Control.switchTrace := false
        val _ = Control.printBinds := false
        val (success, newContextAndCompileUnitStamp) =
            Top.run
                context
                compileUnitStamp
                parameter
                {
                  interactionMode = Top.Prelude,
                  initialSourceChannel = preludeChannel,
                  initialSourceName = preludePath,
                  getBaseDirectory = fn () => preludeDir
                }
                handle e =>
                       (
                         #close preludeChannel ();
                         Control.switchTrace := currentSwitchTrace;
                         Control.printBinds := currentPrintBinds;
                         raise e
                       )

        val _ =Control.switchTrace := currentSwitchTrace
        val _ = Control.printBinds := currentPrintBinds
      in
        newContextAndCompileUnitStamp
      end

  fun resumePrelude
          (parameter : Top.sysParam) preludePath preludeChannel = 
      let
        val reader =
            {
              getByte =
              fn () =>
                 case #receive preludeChannel () of
                   SOME byte => byte
                 | NONE => raise Fail "unexpected EOF of library",
              getPos = #getPos preludeChannel,
              seek = #seek preludeChannel
            }
        val _ = print "restoring static environment..."
        val contextAndCompileUnitStamp =
            Top.unpickle (Pickle.makeInstream reader)
            handle exn =>
                   raise Fail ("malformed compiled code:" ^ exnMessage exn)
        val _ = print "done\n"

        val session = #session parameter
        fun execute () =
            case StandAloneSession.loadExecutable preludeChannel of
              SOME executable => (#execute session executable; execute ())
            | NONE => ()
        val _ = print "restoring dynamic environment..."
        val _ = execute ()
        val _ = print "done\n"
      in
        contextAndCompileUnitStamp
      end

  fun compile
      {
        preludeFileName,
        isCompiledPrelude,
        preludeChannel,
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
          val _ = GlobalCounters.stop()
              handle exn => raise exn
          val initializeParameter = 
              {
                session = session,
                standardOutput = outputChannel, (* no output expected. *)
                standardError = outputChannel,
                loadPathList = ["."],
                getVariable = OS.Process.getEnv
              }
          val (context, compileUnitStamp) = 
              (if isCompiledPrelude then resumePrelude else compilePrelude)
                  initializeParameter preludeFileName preludeChannel
          val _ = #reset Counter.root ()
          val compileTimer = ProcessTimer.createTimer ()
          val _ = 
              if
                #1
                (Top.run
                  context
                  compileUnitStamp
                  initializeParameter
                  {
                    interactionMode = Top.NonInteractive {stopOnError = true},
                    initialSourceChannel = sourceChannel,
                    initialSourceName = sourceFileName,
                    getBaseDirectory = fn () => U.getDirectory sourceFileName
                  })
              then ()
              else raise Fail "cannot compile benchmark."
          val compileTime = ProcessTimer.getTime compileTimer
          val _ = print ("end compile: " ^ sourceFileName ^ "\n")

          fun getProfile counterName =
              case #find Counter.root counterName of
                SOME (Counter.CounterSet (Counter.CounterSetInternal topSet)) =>
                (case #find topSet "elapsed time" of
                   SOME (Counter.CounterSet
                           (Counter.CounterSetInternal timeSet)) =>
                   foldr (fn (Counter.ElapsedTimeCounter x, z) =>
                             (counterName, #name x, #getTime x ()) :: z
                           | (_, z) => z)
                         nil
                         (#listCounters timeSet Counter.ORDER_OF_ADDITION)
                 | _ => nil)
              | _ => nil

          val profile = getProfile "Top" @ getProfile "assembler"
        in
          #close session ();
          (compileTime, profile)
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
        preludeFileName,
        preludeChannel,
        isCompiledPrelude,
        sourceFileName,
        sourceChannel,
        compileOutputChannel,
        executeOutputChannel
      } =
      let
        val executableFileName = U.replaceExt "imo" sourceFileName
        val (compileTime, compileProfile) =
            U.finally
                (FileChannel.openOut {fileName = executableFileName})
                (fn executableChannel =>
                    compile
                        {
                          preludeFileName = preludeFileName,
                          preludeChannel = preludeChannel,
                          isCompiledPrelude = isCompiledPrelude,
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
          compileProfile = compileProfile,
          executionTime = executionTime,
          exitStatus = exitStatus
        }
      end

  (***************************************************************************)

end
