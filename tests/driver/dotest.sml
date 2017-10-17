val _ = Compiler.init ()
val _ = SMLUnit.TextUITestRunner.runTest {output = TextIO.stdOut} tests
        handle _ => ()
val _ = TempFile.cleanup ()
