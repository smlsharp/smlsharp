(**
 * 
 * @author YAMATODANI Kiyoshi
 * @version $Id: BenchmarkRunner.sml,v 1.16 2007/01/26 09:33:15 kiyoshiy Exp $
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
          (parameter : Top.contextParameter) preludePath preludeChannel = 
      let
        val context = Top.initialize parameter

        val preludeDir = U.getDirectory preludePath

        val currentSwitchTrace = !Control.switchTrace
        val currentPrintBinds = !Control.printBinds
      in
        Control.switchTrace := false;
        Control.printBinds := false;
        Top.run
            context
            {
              interactionMode = Top.Prelude,
              initialSource = preludeChannel,
              initialSourceName = preludePath,
              getBaseDirectory = fn () => preludeDir
            }
            handle e =>
                   (
                     #close preludeChannel ();
                     Control.switchTrace := currentSwitchTrace;
                     Control.printBinds := currentPrintBinds;
                     raise e
                   );

        Control.switchTrace := currentSwitchTrace;
        Control.printBinds := currentPrintBinds;

        context
      end

  fun resumePrelude
          (parameter : Top.contextParameter) preludePath preludeChannel = 
      let
        fun reader () =
            case #receive preludeChannel () of
              SOME byte => byte
            | NONE => raise Fail "unexpected EOF of library"
        val _ = print "restoring static environment..."
        val context =
            Top.unpickle parameter (Pickle.makeInstream reader)
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
        context
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
          val initializeParameter = 
              {
                session = session,
                standardOutput = outputChannel, (* no output expected. *)
                standardError = outputChannel,
                loadPathList = ["."],
                getVariable = OS.Process.getEnv
              }
          val context = 
              (if isCompiledPrelude then resumePrelude else compilePrelude)
                  initializeParameter preludeFileName preludeChannel
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
        val compileTime =
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
          executionTime = executionTime,
          exitStatus = exitStatus
        }
      end

  (***************************************************************************)

end