val _ = SMLUnit.TextUITestRunner.runTest
          {output = TextIO.stdOut}
          (TestDictionary.suite ())

(*
  Sample session:
    - TextUITestRunner.runTest () (TestDictionary.suite ());
    ....F
    tests = 5, failures = 1, errors = 0
    val it = () : unit
*)

val () = OS.Process.exit OS.Process.success
