(**
 * 
 * @author YAMATODANI Kiyoshi
 * @version $Id: Main.sml,v 1.9 2007/01/26 09:33:15 kiyoshiy Exp $
 *)
functor Main(structure Printer : RESULT_PRINTER
             structure SessionMaker : SESSION_MAKER) =
struct

  (***************************************************************************)

  structure C = Control
  structure Driver =
  TestDriver(
              structure TestCaseRunner = TestCaseRunner(SessionMaker)
              structure Printer = Printer
            )

  (***************************************************************************)

  val libdir = SMLSharpConfiguration.LibDirectory
  val minimumPreludePath =
      libdir ^ "/" ^ SMLSharpConfiguration.MinimumPreludeFileName
  val PreludePath = libdir ^ "/" ^ SMLSharpConfiguration.PreludeFileName
  val compiledPreludePath =
      libdir ^ "/" ^ SMLSharpConfiguration.CompiledPreludeFileName

  val USAGE = "prelude expectedDirectory resultDirectory sourcePath1 ..."

  fun isSuffix (string, suffix) =
      let
        val stringlen = size string
        val suffixlen = size suffix
      in
        suffixlen <= stringlen
        andalso
        suffix = String.substring (string, stringlen - suffixlen, suffixlen)
      end

  fun main
        (_, prelude :: expectedDirectory :: resultDirectory :: sourcePaths) =
      (
       GlobalCounters.stop()
       handle exn => raise exn;
       print ("prelude = [" ^ prelude ^ "]\n");
        Control.switchTrace := false;
        C.setControlOptions "IML_" OS.Process.getEnv;
        VM.instTrace := false;
        VM.stateTrace := false;
        VM.heapTrace := false;
        Driver.runTests
        {
          prelude = if prelude = "" then compiledPreludePath else prelude,
          isCompiledPrelude = prelude = "" orelse isSuffix(prelude, "smc"),
          sourcePaths = sourcePaths,
          expectedDirectory = expectedDirectory,
          resultDirectory = resultDirectory
        };
        OS.Process.success
      )
    | main _ =
      (print USAGE; OS.Process.failure)

  (***************************************************************************)

end

structure TextMLMain = Main(structure Printer = TextResultPrinter
                            structure SessionMaker = SessionMaker_ML)
structure TextRemoteMain = Main(structure Printer = TextResultPrinter
                                structure SessionMaker = SessionMaker_Remote)
structure HTMLMLMain = Main(structure Printer = HTMLResultPrinter
                            structure SessionMaker = SessionMaker_ML)
structure HTMLRemoteMain = Main(structure Printer = HTMLResultPrinter
                                structure SessionMaker = SessionMaker_Remote)
