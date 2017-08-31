(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: TestMain.sml,v 1.1 2005/12/14 09:38:29 kiyoshiy Exp $
 *)
structure TestMain =
struct

  fun test () =
      let val tests = UtilTest.suite ()
      in SMLUnit.TextUITestRunner.runTest {output = TextIO.stdOut} tests
      end

end
