(**
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: TestMain.sml,v 1.1 2007/05/20 03:53:26 kiyoshiy Exp $
 *)
structure TestMain =
struct

  fun test () =
      let val tests = FFITest.suite ()
      in SMLUnit.TextUITestRunner.runTest {output = TextIO.stdOut} tests
      end

end