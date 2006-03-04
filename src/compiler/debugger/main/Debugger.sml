(**
 * debugger implementation.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Debugger.sml,v 1.6 2006/02/28 16:11:01 kiyoshiy Exp $
 *)
structure Debugger : DEBUGGER =
struct

  (***************************************************************************)

  open BasicTypes
  structure CTX = Context
  structure CVP = CellValuePrinter
  structure E = Executable
  structure H = Heap
  structure I = Instructions
  structure RE = RuntimeErrors
  structure RT = RuntimeTypes
  structure U = Utility

  (***************************************************************************)

  type context = CTX.context

  (***************************************************************************)

  fun onLoadExecutables
          (context as {sourceExecutableMap, ...} : context) executables =
      let
        fun register (executable : RT.executable, map) =
            let
              val fileNames =
                  E.getFileNamesOfLocationTable (#locationTable executable)
              fun registerFileName (fileName, map) = 
                  let
                    val entries = Option.getOpt(SEnv.find(map, fileName), [])
                  in SEnv.insert(map, fileName, executable :: entries)
                  end
            in
              foldl registerFileName map fileNames
            end
        val _ =
            sourceExecutableMap
            := foldl register (!sourceExecutableMap) executables
      in
        print "source files:\n";
        app
            (fn name => print ("  " ^ name ^ "\n"))
            (CTX.getAllSourceFilesInContext context)
      end

  fun onBreakPointHit
          (context as {sourceExecutableMap, breakPointTable, ...} : context)
          (VM : VM.VM)
          (codeRef as {executable, offset} : RT.codeRef) =
      case BreakPointTable.findByCodeRef (breakPointTable, codeRef) of
        NONE =>
        (print "cannot find breakpoint\n"; (I.OPCODE_DebuggerBreak, true))
      | SOME (breakPoint, originalOpcode) =>
        let
        in
          print ("break point: " ^ Int.toString breakPoint
                 ^ " at"
                 ^ " offset = " ^ UInt32.toString offset
                 ^ " opcode = " ^ Instructions.opcodeToString originalOpcode
                 ^ "\n");

          CommandShell.start context (SOME VM);

          (
            originalOpcode,
            (* return true, if this break point is not deleted. *)
            isSome(BreakPointTable.findByCodeRef (breakPointTable, codeRef))
          )
        end

  fun onUncaughtException 
          (context as {sourceExecutableMap, breakPointTable, ...} : context)
          (VM : VM.VM)
          (codeRef as {executable, offset} : RT.codeRef)
          exnValue =
      let
        val exnStrings = CVP.valueToStrings VM exnValue
      in
        print ("uncaught exception:\n");
        app (fn string => (print string; print "\n")) exnStrings;
        print ("at offset = " ^ UInt32.toString offset ^ "\n");

        CommandShell.start context (SOME VM)
      end

  fun getErrorMessage exn =
      case exn of
        RE.InvalidCode message => message
      | RE.InvalidStatus message => message
      | RE.UnexpectedPrimitiveArguments message => message
      | RE.Error message => message
      | H.Error message => message
      | _ => exnMessage exn

  fun onRuntimeError
          (context as {sourceExecutableMap, breakPointTable, ...} : context)
          (VM : VM.VM)
          (codeRef as {executable, offset} : RT.codeRef)
          exn =
      case exn of
        CommandShell.Quit => raise exn
      | CommandShell.Run => raise exn
      | _ =>
        (
          print ("runtime error :(" ^ exnName exn ^ ") " ^ getErrorMessage exn
                 ^ " at"
                 ^ " offset = " ^ UInt32.toString offset
                 ^ "\n");

          CommandShell.start context (SOME VM)
        )

  fun execute context executables =
      let
        val VM =
            VM.initialize
                {
                  name = "VMEmulator",
                  arguments = !(#arguments context),
                  heapSize = !(#heapSize context),
                  frameStackSize = !(#frameStackSize context),
                  handlerStackSize = !(#handlerStackSize context),
                  globalCount = !(#globalCount context),
                  standardInput =
                  TextIOChannel.openIn{inStream = TextIO.stdIn},
                  standardOutput =
                  TextIOChannel.openOut{outStream = TextIO.stdOut},
                  standardError =
                  TextIOChannel.openOut{outStream = TextIO.stdErr},
                  primitives = PrimitiveTable.map,
                  debuggerOpt =
                  SOME
                      {
                        onBreakPointHit = onBreakPointHit context,
                        onUncaughtException = onUncaughtException context,
                        onRuntimeError = onRuntimeError context
                      }
                }
      in
        app (fn executable => VM.execute (VM, executable)) executables;
        print "Program exited normally\n";
        CommandShell.start context NONE
      end
        handle CommandShell.Run => execute context executables

  (***************************************************************************)

  fun start executables =
      let
        val context = CTX.create ()
        val _ = onLoadExecutables context executables
        val _ = CommandShell.start context NONE handle CommandShell.Run => ()
      in
        execute context executables
      end
        handle CommandShell.Quit => ()

  (***************************************************************************)

end
