(**
 * Copyright (c) 2006, Tohoku University.
 *
 * run the interactive session with runtime
 * @author YAMATODANI Kiyoshi
 * @version $Id: Main.sml,v 1.12 2006/02/18 04:59:20 ohori Exp $
 *)
structure Main =
struct

  (***************************************************************************)

  structure PU = PathUtility

  (***************************************************************************)

  (* Do not edit these constants.
   * You can set these switch on prompt.
   * - Main.printPrelude := true;
   * - Main.tracePrelude := true;
   *)
  val loadPrelude = ref true
  val printPrelude = ref false
  val tracePrelude = ref false
  val useBasis = ref false

  val _ = Top.printBinds := true
  val _ = Top.switchTrace := false

  (* use the standard preludes. *)
  val minimumPreludePath = LibConfiguration.MinimumPreludePath
  val BasisPath = LibConfiguration.BasisPath

  val usage = "usage: imli [-usebasis] [{ -e expression | file }]* \n"

  (**
   * If any input source is specified, the compiler runs in filter mode.
   * Otherwise, it runs in interactive mode.
   * <dl>
   *   <dt>filter mode</dt>
   *   <dd>no prompt. no binding printed.</dd>
   *   <dt>interactive mode</dt>
   *   <dd>prompt. binding is printed.</dd>
   *   <dd></dd>
   * </dl>
   *)
  fun parseArguments arguments =
      let
        fun getStdInSource () =
            {
              interactionMode = Top.Interactive,
              initialSource =
              TextIOChannel.openIn {inStream = TextIO.stdIn},
              initialSourceName = "stdIn",
              getBaseDirectory = OS.FileSys.getDir
            }
        fun parse [] sources = List.rev sources
          | parse ("-usebasis" :: remains) sources =
            (useBasis := true; parse remains sources)
          | parse ("-e" :: expression :: remains) sources =
            let
              fun getSource () =
                  {
                    interactionMode = Top.NonInteractive {stopOnError = true},
                    initialSource =
                    TextIOChannel.openIn
                        {inStream = TextIO.openString expression},
                    initialSourceName = "argument",
                    getBaseDirectory = OS.FileSys.getDir
                  }
            in parse remains (getSource :: sources)
            end
          | parse (sourceFileName :: remains) sources =
            let
              val sourceDir = #dir(PU.splitDirFile sourceFileName)
              fun getSource () = 
                  {
                    interactionMode = Top.NonInteractive {stopOnError = true},
                    initialSource =
                    FileChannel.openIn {fileName = sourceFileName},
                    initialSourceName = sourceFileName,
                    getBaseDirectory = fn () => sourceDir
                  }
            in parse remains (getSource :: sources)
            end
        val sources = parse arguments []
      in
        case sources of
          [] => (* interactive mode *) [getStdInSource]
        | _ => (* filter mode *) (Top.printBinds := false; sources)
      end

  fun main (commandName, arguments) =
      let
        val sources = parseArguments arguments

        val preludePath = if !useBasis then BasisPath else minimumPreludePath
        val preludeDir = 
            OS.FileSys.fullPath(#dir(PathUtility.splitDirFile preludePath))
        val preludeChannel = FileChannel.openIn {fileName = preludePath}

        val proxy = RuntimeProxyFactory.createInstance ()
        val STDINChannel = TextIOChannel.openIn {inStream = TextIO.stdIn}
        val STDOUTChannel = TextIOChannel.openOut {outStream = TextIO.stdOut}
        val STDERRChannel = TextIOChannel.openOut {outStream = TextIO.stdErr}

        val sessionParameter = 
            {
              terminalInputChannel = STDINChannel,
              terminalOutputChannel = STDOUTChannel,
              terminalErrorChannel = STDERRChannel,
              runtimeProxy = proxy
            }
        val session = InteractiveSession.openSession sessionParameter
        val context = 
            Top.initialize
            {
              session = session,
              standardOutput = STDOUTChannel,
              standardError = STDERRChannel,
              loadPathList = ["."],
              getVariable = OS.Process.getEnv
            }

        val currentSwitchTrace = !Top.switchTrace
        val currentPrintBinds = !Top.printBinds
      in
        (
          Top.switchTrace := !tracePrelude;
          Top.printBinds := !printPrelude;
          if !loadPrelude
          then
            if
              (Top.run
               context
               {
                 interactionMode = Top.NonInteractive {stopOnError = true},
                 initialSource = preludeChannel,
                 initialSourceName = preludePath,
                 getBaseDirectory = fn () => preludeDir
               })
              handle e => (#close preludeChannel (); raise e)
            then ()
            else raise Fail "prelude cannot compile."
          else ();
          #close preludeChannel ();

          Top.switchTrace := currentSwitchTrace;
          Top.printBinds := currentPrintBinds;

          List.all (* stop if any compilation fails. *)
              (fn getSource => Top.run context (getSource ()))
              sources;

          #close session ();
          #release proxy ();
          OS.Process.success
        ) handle exn => (#close session (); #release proxy (); raise exn)
      end
        handle exn =>
               let
                 val exn = 
                     case exn of
                       SessionTypes.Error exn => exn
                     | _ => exn
               in
                 print ("Error:" ^ (exnMessage exn) ^ "\n");
                 app
                     (fn line => print (line ^ "n"))
                     (SMLofNJ.exnHistory exn);
                 OS.Process.failure
               end

  (***************************************************************************)

end;
