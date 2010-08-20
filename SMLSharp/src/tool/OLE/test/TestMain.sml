(**
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure TestMain =
struct

  structure T = SMLUnit.Test

  fun suite () =
      T.TestList
          [
            T.TestLabel ("Array1Tester", Array1Tester.suite ()),
            T.TestLabel ("Reference2Tester", Reference2Tester.suite ()),
            T.TestLabel ("Reference1Tester", Reference1Tester.suite ()),
            T.TestLabel ("Enum1Tester", Enum1Tester.suite ()),
            T.TestLabel ("Property1Tester", Property1Tester.suite ()),
            T.TestLabel ("Exception1Tester", Exception1Tester.suite ()),
            T.TestLabel ("MethodCall1Tester", MethodCall1Tester.suite ()),
            T.TestLabel ("DataTypes2Tester", DataTypes2Tester.suite ()),
            T.TestLabel ("DataTypes1Tester", DataTypes1Tester.suite ())
          ]

  fun init () =
      let
        val _ = OLE.initialize [OLE.COINIT_MULTITHREADED]

        val _ = DataTypes1Tester.init ()
        val _ = DataTypes2Tester.init ()
        val _ = MethodCall1Tester.init ()
        val _ = Exception1Tester.init ()
        val _ = Property1Tester.init ()
        val _ = Enum1Tester.init ()
        val _ = Reference1Tester.init ()
        val _ = Reference2Tester.init ()
        val _ = Array1Tester.init ()
      in
        ()
      end

  fun test () =
      let
        val tests = suite ()
      in SMLUnit.TextUITestRunner.runTest {output = TextIO.stdOut} tests
      end

end
