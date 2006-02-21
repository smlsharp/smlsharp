(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: TestMain.sml,v 1.3 2005/04/09 14:46:05 kiyoshiy Exp $
 *)
structure TestMain =
struct

  fun test () =
      let val tests = AssembleTest.suite ()
      in SMLUnit.TextUITestRunner.runTest {output = TextIO.stdOut} tests
      end

end