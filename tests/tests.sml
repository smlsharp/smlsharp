open SMLUnit.Test

val tests =
  TestList
    [
      TestLabel ("SMLFormat", PPLibTest.suite ()),
      TestLabel ("BasisTests", TestList (TestRequiredModules.tests ())),
      TestLabel ("BasisTests", TestList (TestOptionalModules.tests ())),
(*
      TestLabel ("NaturalJoin", TestNaturalJoin.tests),
*)
      TestLabel ("LoadFile", LoadFileTests.tests),
      TestLabel ("RegressionTests", RegressionTests.tests),
      TestLabel ("TestInteractivePrinter", TestInteractivePrinter.tests),
      TestLabel ("DocumentTests", DocumentTests.tests),
      TestLabel ("ExampleTests", ExampleTests.tests),
      TestLabel ("CompilerTest", CompilerTest.tests),
      TestList nil
    ]
