(**
 * 
 * @author YAMATODANI Kiyoshi
 * @version $Id: Main.sml,v 1.7 2006/02/15 09:18:00 kiyoshiy Exp $
 *)
functor Main(structure Printer : RESULT_PRINTER
             structure RuntimeRunner : RUNTIME_RUNNER) =
struct

  (***************************************************************************)

  structure C = Control
  structure Driver =
  BenchmarkDriver(
                   structure BenchmarkRunner = BenchmarkRunner(RuntimeRunner)
                   structure Printer = Printer
                 )

  (***************************************************************************)

  val USAGE = "prelude resultDirectory sourcePath1 ..."

  fun main
          (_, prelude :: resultDirectory :: sourcePaths) =
      (
        Control.switchTrace := false;
        C.setControlOptions "IML_" OS.Process.getEnv;
        VM.instTrace := false;
        VM.stateTrace := false;
        VM.heapTrace := false;
        Driver.runBenchmarks
        {
          prelude = prelude,
          sourcePaths = sourcePaths,
          resultDirectory = resultDirectory
        };
        OS.Process.success
      )
    | main _ = (print USAGE; OS.Process.failure)

  (***************************************************************************)

end

structure TextEmulatorMain = Main(structure Printer = TextResultPrinter
                            structure RuntimeRunner = RuntimeRunner_Emulator)
structure TextRemoteMain = Main(structure Printer = TextResultPrinter
                                structure RuntimeRunner = RuntimeRunner_Remote)
structure HTMLEmulatorMain = Main(structure Printer = HTMLResultPrinter
                            structure RuntimeRunner = RuntimeRunner_Emulator)
structure HTMLRemoteMain = Main(structure Printer = HTMLResultPrinter
                                structure RuntimeRunner = RuntimeRunner_Remote)
