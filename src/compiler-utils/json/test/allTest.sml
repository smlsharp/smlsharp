val _ =
    SMLUnit.TextUITestRunner.runTest
    {output = TextIO.stdOut}
    (SMLUnit.Test.TestList
       [
        TestJSONTypes.suite (),
        TestJSON.suite (),
        TestJSONImpl.suite ()
        ]
    )
