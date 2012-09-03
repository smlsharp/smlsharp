(**
 * Copyright (c) 2006, Tohoku University.
 *
 * This module provides the entry point for batch compiler.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Main.sml,v 1.16 2007/12/15 08:30:34 bochao Exp $
 *)
structure Main :
  sig

    val loadPrelude : bool ref
    val printPrelude : bool ref
    val tracePrelude : bool ref
    val useBasis : bool ref

    (** entry point.
     * This is passed to the SMLofNJ.exportFn.
     *)
    val main : string * string list -> OS.Process.status

  end =
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

  val _ = Top.printBinds := false
  val _ = Top.switchTrace := false

  val minimumPreludePath = LibConfiguration.MinimumPreludePath
  val BasisPath = LibConfiguration.BasisPath
  (* ToDo : the file name of runtime should be specified in Configuration. *)
  val RuntimeFileName = "imlrun.exe"

  val usage = "usage: imlc \
              \[-usebasis] \
              \[-o OUTPUTFILE] \
              \{ -e expression |filename | - }* \n"

  fun parseArguments arguments =
      let
        val outputFileNameRef = ref "a.imo"
        fun parse [] sources = List.rev sources
          | parse ("-usebasis" :: remains) sources =
            (useBasis := true; parse remains sources)
          | parse ("-o" :: outputFileName :: remains) sources =
            (outputFileNameRef := outputFileName; parse remains sources)
          | parse ("-" :: remains) sources =
            let
              fun getSource () =
                  {
                    interactionMode = Top.Interactive,
                    initialSource =
                    TextIOChannel.openIn {inStream = TextIO.stdIn},
                    initialSourceName = "stdIn",
                    getBaseDirectory = OS.FileSys.getDir
                  }
            in parse remains (getSource :: sources)
            end
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
        (!outputFileNameRef, sources)
      end

  fun writeMagicNumberHeader outputChannel =
      #print
          (CharacterStreamWrapper.wrapOut outputChannel)
          ("#!/usr/bin/env " ^ RuntimeFileName ^ "\n")

  fun main (commandName, arguments) =
      let
        val (outputFileName, sources) = parseArguments arguments
        val _ = if null sources then raise Fail usage else ()

        (* NOTE: useBasis may have been updated by parseArguments. *)
        val preludePath = if !useBasis then BasisPath else minimumPreludePath
        val preludeDir = 
            OS.FileSys.fullPath(#dir(PathUtility.splitDirFile preludePath))

        val outputChannel = FileChannel.openOut {fileName = outputFileName}
        val _ = writeMagicNumberHeader outputChannel
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

        val preludeChannel = FileChannel.openIn {fileName = preludePath}

        val currentSwitchTrace = !Top.switchTrace
        val currentPrintBinds = !Top.printBinds
      in
        Top.switchTrace := !tracePrelude;
        Top.printBinds := !printPrelude;
        if !loadPrelude
        then
            let
                val (success, updatedContext) =
                    (Top.run
                         context
                         {
                          interactionMode = Top.NonInteractive {stopOnError = true},
                          initialSource = preludeChannel,
                          initialSourceName = preludePath,
                          getBaseDirectory = fn () => preludeDir
                                                      })
                    handle e => (#close preludeChannel (); raise e)
            in
                if success
                then ()
                else raise Fail "prelude compile error"
            end
        else ();
        #close preludeChannel ();

        Top.switchTrace := currentSwitchTrace;
        Top.printBinds := currentPrintBinds;

        List.all (* stop if any compilation fails. *)
            (fn getSource => Top.run context (getSource ()))
            sources;

        #close session ();
        #close outputChannel ();

        FileSysUtil.setFileModeExecutable outputFileName;

        if !Control.doProfile then print (Counter.dump ()) else ();

        OS.Process.success
      end
        handle error => (print (exnMessage error); OS.Process.failure)

  (***************************************************************************)

end
