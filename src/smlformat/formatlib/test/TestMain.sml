(**
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure TestMain =
struct

  fun test () =
      let val tests = PPLibTest.suite()
      in SMLUnit.TextUITestRunner.runTest {output = TextIO.stdOut} tests
      end

end