(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: TestMain.sml,v 1.2 2006/01/02 07:13:27 kiyoshiy Exp $
 *)
structure TestMain =
struct

  fun test () =
      let val tests = InstructionsTest.suite ()
      in SMLUnit.TextUITestRunner.runTest {output = TextIO.stdOut} tests
      end

end