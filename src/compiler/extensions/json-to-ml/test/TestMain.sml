structure TestMain =
struct
  fun test () =
      let
        val tests = SMLUnit.Test.TestList
                      [SMLUnit.Test.TestLabel
                         ("JSONToML001",
                          JSONToML001.suite ())
                      ]
      in SMLUnit.TextUITestRunner.runTest
           {output = TextIO.stdOut}
           tests
      end
end
