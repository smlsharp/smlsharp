(**
 * @author YAMATODANI Kiyoshi
 * @copyright (C) 2021 SML# Development Team.
 *)
structure TestMain =
struct

  fun test () =
      let val tests = PPLibTest.suite()
      in SMLUnit.TextUITestRunner.runTest {output = TextIO.stdOut} tests
      end

end