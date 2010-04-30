structure TestMain =
struct

  fun test () =
      let val tests = SessionTest.suite ()
      in SMLUnit.TextUITestRunner.runTest {output = TextIO.stdOut} tests
      end

end