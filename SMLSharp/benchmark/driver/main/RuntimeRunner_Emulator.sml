(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: RuntimeRunner_Emulator.sml,v 1.4 2007/06/01 09:40:59 kiyoshiy Exp $
 *)
structure RuntimeRunner_Emulator : RUNTIME_RUNNER =
struct

  (***************************************************************************)

  structure BT = BasicTypes
  structure ES = ExecutableSerializer
  structure SAS = StandAloneSession
  structure U = Utility

  (***************************************************************************)

  (* initialize virtual machine *)
  val heapSize = 0w1000000 : BasicTypes.UInt32
  val frameStackSize = 0w100000 : BasicTypes.UInt32
  val handlerStackSize = 0w100000 : BasicTypes.UInt32
  val globalCount = 0w10000 : BasicTypes.UInt32

  fun loadExecutables channel =
      let 
        fun loop executables = 
            case SAS.loadExecutable channel of
              NONE => rev executables
            | SOME executable => loop (executable :: executables)
      in
        loop []
      end

  fun execute {executableFileName, outputChannel} =
      let
        val executables = 
            U.finally
                (FileChannel.openIn {fileName = executableFileName})
                loadExecutables
                U.closeInputChannel
        val VM =
	    VM.initialize
		{
		  name = "VMEmulator",
		  arguments = [],
		  heapSize = heapSize,
		  frameStackSize = frameStackSize,
		  handlerStackSize = handlerStackSize,
		  globalCount = globalCount,
		  standardInput =
                  TextIOChannel.openIn{inStream = TextIO.stdIn},
		  standardOutput = outputChannel,
		  standardError = outputChannel,
		  primitives = PrimitiveTable.map,
                  debuggerOpt = NONE
		}
        val session = VMSession.openSession {VM = VM}
      in
        app (fn executable => #execute session executable) executables;
        OS.Process.success
      end
        handle SessionTypes.Failure exn => raise exn
             | SessionTypes.Fatal exn => raise exn

  (***************************************************************************)

end
