structure TestMain =
struct

  fun test () =
      let val tests = SMLDocTest.suite ()
      in SMLUnit.TextUITestRunner.runTest {output = TextIO.stdOut} tests
      end

end