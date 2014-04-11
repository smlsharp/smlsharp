(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: TestMain.sml,v 1.1 2006/01/11 11:48:00 kiyoshiy Exp $
 *)
structure TestMain =
struct

  fun test () =
      let val tests = TypesTest.suite ()
      in SMLUnit.TextUITestRunner.runTest {output = TextIO.stdOut} tests
      end

end
