(**
 * 
 * @author YAMATODANI Kiyoshi
 * @version $Id: Main.sml,v 1.9 2007/01/26 09:33:15 kiyoshiy Exp $
 *)
functor Main(structure Printer : RESULT_PRINTER
             structure BenchmarkRunner : BENCHMARK_RUNNER) =
struct

  (***************************************************************************)

  structure C = Control
  structure Driver =
  BenchmarkDriver(
                   structure BenchmarkRunner = BenchmarkRunner
                   structure Printer = Printer
                 )
  structure U = Utility

  (***************************************************************************)

  val libdir = Configuration.LibDirectory
  val minimumPreludePath = libdir ^ "/" ^ Configuration.MinimumPreludeFileName
  val PreludePath = libdir ^ "/" ^ Configuration.PreludeFileName
  val compiledPreludePath = libdir ^ "/" ^ Configuration.CompiledPreludeFileName

  val USAGE = "prelude resultDirectory sourcePath1 ..."

  fun main
          (_, prelude :: resultDirectory :: sourcePaths) =
      (
        Control.switchTrace := false;
        Control.printBinds := false;
        Control.printWarning := false;
        Control.checkType := false;
        Control.generateExnHistory := true;

        C.setControlOptions "IML_" OS.Process.getEnv;

        VM.instTrace := false;
        VM.stateTrace := false;
        VM.heapTrace := false;

        Driver.runBenchmarks
        {
          prelude = if prelude = "" then compiledPreludePath else prelude,
          isCompiledPrelude = prelude = "" orelse U.isSuffix(prelude, "smc"),
          sourcePaths = sourcePaths,
          resultDirectory = resultDirectory
        };

        OS.Process.success
      )
    | main _ = (print USAGE; OS.Process.failure)

  (***************************************************************************)

end

structure TextEmulatorMain =
  Main(structure Printer = TextResultPrinter
       structure BenchmarkRunner = BenchmarkRunner(RuntimeRunner_Emulator))
structure TextRemoteMain =
  Main(structure Printer = TextResultPrinter
       structure BenchmarkRunner = BenchmarkRunner(RuntimeRunner_Remote))
structure HTMLEmulatorMain =
  Main(structure Printer = HTMLResultPrinter
       structure BenchmarkRunner = BenchmarkRunner(RuntimeRunner_Emulator))
structure HTMLRemoteMain =
  Main(structure Printer = HTMLResultPrinter
       structure BenchmarkRunner = BenchmarkRunner(RuntimeRunner_Remote))
structure ParsableEmulatorMain =
  Main(structure Printer = ParsableResultPrinter
       structure BenchmarkRunner = BenchmarkRunner(RuntimeRunner_Emulator))
structure ParsableRemoteMain =
  Main(structure Printer = ParsableResultPrinter
       structure BenchmarkRunner = BenchmarkRunner(RuntimeRunner_Remote))
structure ParsableNativeMain =
  Main(structure Printer = ParsableResultPrinter
       structure BenchmarkRunner = BenchmarkRunner_Native)
