(**
 * run the VM simulator.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Main.sml,v 1.66 2007/02/19 14:11:56 kiyoshiy Exp $
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

  val _ = Control.printBinds := true
  val _ = Control.switchTrace := true

(*
  val libdir = Configuration.SourceRoot ^ "/src/lib/"
*)
  val libdir = Configuration.LibDirectory
  val minimumPreludePath = libdir ^ "/" ^ Configuration.MinimumPreludeFileName
  val PreludePath = libdir ^ "/" ^ Configuration.PreludeFileName
  val compiledPreludePath = libdir ^ "/" ^ Configuration.CompiledPreludeFileName

  (* initialize virtual machine *)
  val heapSize = ref (0w1000000 : BasicTypes.UInt32)
  val frameStackSize = ref (0w10000 : BasicTypes.UInt32)
  val handlerStackSize = ref (0w10000 : BasicTypes.UInt32)
  val globalCount = ref (0w10000 : BasicTypes.UInt32)

  fun compilePrelude (parameter : Top.contextParameter) preludePath = 
      let
        val context = Top.initialize parameter

        val preludeDir = 
            OS.FileSys.fullPath(#dir(PathUtility.splitDirFile preludePath))
        val preludeChannel = FileChannel.openIn {fileName = preludePath}

        val currentSwitchTrace = !Control.switchTrace
        val currentPrintBinds = !Control.printBinds
      in
        Control.switchTrace := !tracePrelude;
        Control.printBinds := !printPrelude;
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

        #close preludeChannel ();

        context
      end

  fun resumePrelude (parameter : Top.contextParameter) preludePath = 
      let
        val preludeChannel = FileChannel.openIn {fileName = preludePath}
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
        #close preludeChannel ();
        context
      end

  fun main () =
      let
        val _ = #reset Counter.root ()

        val (isCompiledPrelude, preludePath) =
            if !useBasis
            then (true, compiledPreludePath)
            else (false, minimumPreludePath)

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
        val context =
            if !loadPrelude
            then
              if isCompiledPrelude
              then resumePrelude topInitializeParameter preludePath
              else compilePrelude topInitializeParameter preludePath
            else Top.initialize topInitializeParameter
      in

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
