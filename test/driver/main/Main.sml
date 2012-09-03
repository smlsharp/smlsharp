(**
 * 
 * @author YAMATODANI Kiyoshi
 * @version $Id: Main.sml,v 1.8 2006/02/15 09:18:00 kiyoshiy Exp $
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

  val USAGE = "prelude expectedDirectory resultDirectory sourcePath1 ..."

  fun main
          (_, prelude :: expectedDirectory :: resultDirectory :: sourcePaths) =
      (
        Control.switchTrace := false;
        C.setControlOptions "IML_" OS.Process.getEnv;
        VM.instTrace := false;
        VM.stateTrace := false;
        VM.heapTrace := false;
        Driver.runTests
        {
          prelude = prelude,
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
