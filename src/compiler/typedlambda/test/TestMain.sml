(**
 * @author Liu Bochao
 * @version $Id: TestMain.sml,v 1.1 2006/03/15 02:34:43 bochao Exp $
 *)
structure TestMain =
struct

  fun test () =
      let val tests = TypedLambdaTest.suite ()
      in SMLUnit.TextUITestRunner.runTest {output = TextIO.stdOut} tests
      end

end