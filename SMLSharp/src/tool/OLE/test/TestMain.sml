structure TestMain =
struct

  structure T = SMLUnit.Test

  fun suite () =
      T.TestList
          [
            T.TestLabel ("DataTypes4Tester", DataTypes4Tester.suite ()),
            T.TestLabel ("DataTypes3Tester", DataTypes3Tester.suite ()),
            T.TestLabel ("DataTypes2Tester", DataTypes2Tester.suite ()),
            T.TestLabel ("DataTypes1Tester", DataTypes1Tester.suite ())
          ]

  fun init () =
      let
        val _ = OLE.initialize [OLE.COINIT_MULTITHREADED]

        val _ = DataTypes1Tester.init ()
        val _ = DataTypes2Tester.init ()
        val _ = DataTypes3Tester.init ()
        val _ = DataTypes4Tester.init ()
      in
        ()
      end

  fun test () =
      let
        val tests = suite ()
      in SMLUnit.TextUITestRunner.runTest {output = TextIO.stdOut} tests
      end

end
