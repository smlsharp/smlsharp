(**
 * Copyright (c) 2006, Tohoku University.
 *
 * run the VM simulator.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Main.sml,v 1.60 2006/02/21 01:50:26 katsuu Exp $
 *)
structure Main =
struct

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

  val doPickle = ref false

  val _ = Control.printBinds := true
  val _ = Control.switchTrace := true

  val libdir = Configuration.BuildRoot ^ "/src/lib/"
  val minimumPreludePath = libdir ^ Configuration.MinimumPreludeFileName
  val BasisPath = libdir ^ Configuration.BasisFileName

  (* initialize virtual machine *)
  val heapSize = ref (0w1000000 : BasicTypes.UInt32)
  val frameStackSize = ref (0w10000 : BasicTypes.UInt32)
  val handlerStackSize = ref (0w10000 : BasicTypes.UInt32)
  val globalCount = ref (0w10000 : BasicTypes.UInt32)

  fun main () =
      let
        val preludePath = if !useBasis then BasisPath else minimumPreludePath
        val preludeDir = 
            OS.FileSys.fullPath(#dir(PathUtility.splitDirFile preludePath))

        val VM =
            VM.initialize
                {
                  name = "VMEmulator",
                  arguments = [],
                  heapSize = !heapSize,
                  frameStackSize = !frameStackSize,
                  handlerStackSize = !handlerStackSize,
                  globalCount = !globalCount,
                  standardInput =
                  TextIOChannel.openIn{inStream = TextIO.stdIn},
                  standardOutput =
                  TextIOChannel.openOut{outStream = TextIO.stdOut},
                  standardError =
                  TextIOChannel.openOut{outStream = TextIO.stdErr},
                  primitives = PrimitiveTable.map,
                  debuggerOpt = NONE
                }
        val topInitializeParameter = 
            {
              session = VMSession.openSession {VM = VM},
              standardOutput =
              TextIOChannel.openOut {outStream = TextIO.stdOut},
              standardError =
              TextIOChannel.openOut {outStream = TextIO.stdErr},
              loadPathList = ["."],
              getVariable = OS.Process.getEnv
            }
        val context = Top.initialize topInitializeParameter
        val preludeChannel = FileChannel.openIn {fileName = preludePath}

        val currentSwitchTrace = !Control.switchTrace
        val currentPrintBinds = !Control.printBinds
      in
        Control.switchTrace := !tracePrelude;
        Control.printBinds := !printPrelude;
        if !loadPrelude
        then
          (Top.run
           context
           {
             interactionMode = Top.NonInteractive {stopOnError = true},
             initialSource = preludeChannel,
             initialSourceName = preludePath,
             getBaseDirectory = fn () => preludeDir
           })
          handle e =>
                 (
                   #close preludeChannel ();
                   Control.switchTrace := currentSwitchTrace;
                   Control.printBinds := currentPrintBinds;
                   raise e
                 )
        else true;
        #close preludeChannel ();

        Control.switchTrace := currentSwitchTrace;
        Control.printBinds := currentPrintBinds;

        if !doPickle
        then
          (
            let
              val outfile = BinIO.openOut "foo.pickle"
              val outstream =
                  Pickle.makeOutstream
                      (fn byte => BinIO.output1 (outfile, byte))
            in
              print "begin pickle...";
              Top.pickle context outstream;
              print "done\n";
              BinIO.closeOut outfile
            end;
            let
              val infile = BinIO.openIn "foo.pickle"
              val instream =
                  Pickle.makeInstream (fn _ => valOf(BinIO.input1 infile))
              val _ = print "begin unpickle...";
                  val newContext = Top.unpickle topInitializeParameter instream
                  val _ = print "done\n";
            in
              BinIO.closeIn infile; newContext
            end;
            ()
          )
        else ();

        if !Control.doProfile
        then (print "\n"; print (Counter.dump ()))
        else ();

        Top.run
        context
        {
          interactionMode = Top.Interactive,
          initialSource = TextIOChannel.openIn {inStream = TextIO.stdIn},
          initialSourceName = "stdIn",
          getBaseDirectory = OS.FileSys.getDir
        }
      end

  (***************************************************************************)

end;
