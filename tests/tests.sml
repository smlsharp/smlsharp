open SMLUnit.Test

val tests =
  TestList
    [
      TestLabel ("NaturalJoin", TestNaturalJoin.tests),
      TestLabel ("RegressionTests", RegressionTests.tests),
      TestLabel ("TestInteractivePrinter", TestInteractivePrinter.tests)
    ]
