(**
 * Copyright (c) 2006, Tohoku University.
 *
 * entry point of the debugger.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Main.sml,v 1.7 2006/02/21 01:50:26 katsuu Exp $
 *)
structure Main =
struct

  (***************************************************************************)

  structure ES = ExecutableSerializer
  structure PU = PathUtility
  structure SAS = StandAloneSession

  (***************************************************************************)

  val loadPrelude = ref true
  val printPrelude = ref false
  val tracePrelude = ref false
  val useBasis = ref false

  val _ = Control.printBinds := false
  val _ = Control.switchTrace := false
  val _ = Control.generateExnHistory := true
  val _ = Control.generateDebugInfo := true

  val minimumPreludePath = Configuration.MinimumPreludePath
  val BasisPath = Configuration.BasisPath

  fun isSourceFile fileName =
      case PU.splitBaseExt fileName of
        {ext = SOME "sml", ...} => true
      | {ext = SOME "ml", ...} => true
      | {ext = SOME "iml", ...} => true
      | _ => false

  fun compile sourceFileName =
      let
        (* NOTE: useBasis may have been updated by parseArguments. *)
        val preludePath = if !useBasis then BasisPath else minimumPreludePath
        val preludeDir = 
            OS.FileSys.fullPath(#dir(PathUtility.splitDirFile preludePath))

        val sourceDir = #dir(PU.splitDirFile sourceFileName)

        val executablesBufferRef = ref NONE
        val outputChannel =
            ByteArrayChannel.openOut {buffer = executablesBufferRef}
        val session =
            StandAloneSession.openSession {outputChannel = outputChannel}
        val context =
            Top.initialize
                {
                  session = session,
                  standardOutput =
                  TextIOChannel.openOut {outStream = TextIO.stdOut},
                  standardError =
                  TextIOChannel.openOut {outStream = TextIO.stdErr},
                  loadPathList = ["."],
                  getVariable = OS.Process.getEnv
                }

        val sourceChannel = FileChannel.openIn {fileName = sourceFileName}
        val preludeChannel = FileChannel.openIn {fileName = preludePath}

        val currentSwitchTrace = !Control.switchTrace
        val currentPrintBinds = !Control.printBinds
      in
        (
          Control.switchTrace := !tracePrelude;
          Control.printBinds := !printPrelude;
          if !loadPrelude
          then
            if
              Top.run
                  context
                  {
                    interactionMode = Top.NonInteractive {stopOnError = true},
                    initialSource = preludeChannel,
                    initialSourceName = preludePath,
                    getBaseDirectory = fn () => preludeDir
                  }
            then ()
            else raise Fail "prelude compile error"
          else ();

          Control.switchTrace := currentSwitchTrace;
          Control.printBinds := currentPrintBinds;

          if
            Top.run
                context 
                {
                  interactionMode = Top.NonInteractive {stopOnError = true},
                  initialSource = sourceChannel,
                  initialSourceName = sourceFileName,
                  getBaseDirectory = fn () => sourceDir
                }
          then ()
          else raise Fail "compile fail";

          #close preludeChannel ();
          #close sourceChannel;
          #close session ();
          #close outputChannel ();
          ByteArrayChannel.openIn {buffer = valOf(!executablesBufferRef)}
        )
        handle exn =>
               (
                 #close preludeChannel ();
                 #close sourceChannel ();
                 raise exn
               )
      end

  fun main fileName =
      let
        val channel = 
            if isSourceFile fileName
            then compile fileName
            else FileChannel.openIn {fileName = fileName}

        fun loop executables = 
            case SAS.loadExecutable channel of
              NONE => rev executables
            | SOME executable => loop (executable :: executables)
        val executableBuffers =
            (loop [] handle exn => (#close channel (); raise exn))
            before #close channel ()

        val executables = map ES.deserialize executableBuffers
      in
        Debugger.start executables;
        OS.Process.success
      end

  (***************************************************************************)

end
