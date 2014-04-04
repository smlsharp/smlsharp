structure TestTest =
struct

  local
    open SMLUnit.Test
  in
  fun test () =
      let
        val tests = 
            TestList
            [TestLabel ("Bool001", Bool001.suite ())]
      in SMLUnit.TextUITestRunner.runTest {output = TextIO.stdOut} tests
      end
  end

end
