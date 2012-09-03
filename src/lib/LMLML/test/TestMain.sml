(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: TestMain.sml,v 1.1 2006/12/11 10:57:04 kiyoshiy Exp $
 *)
structure TestMain =
struct

  fun test () =
      let val tests = MultiByteStringTest.suite ()
      in SMLUnit.TextUITestRunner.runTest {output = TextIO.stdOut} tests
      end

end