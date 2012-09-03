structure TestMain =
struct

  structure T = SMLUnit.Test

  fun suite () =
      T.TestList
          [
            T.TestLabel ("ArrayTest1", ArrayTest1.suite ()),
            T.TestLabel ("MemberAccessTest1", MemberAccessTest1.suite ()),
            T.TestLabel ("ObjectBasicsTest1", ObjectBasicsTest1.suite ()),
            T.TestLabel ("ClassBasicsTest1", ClassBasicsTest1.suite ()),
            T.TestLabel ("ExceptionTest1", ExceptionTest1.suite ()),
            T.TestLabel ("MethodCallTest1", MethodCallTest1.suite ()),
            T.TestLabel ("RenameKeywordTest1", RenameKeywordTest1.suite ()),
            T.TestLabel ("RenameKeywordTest2", RenameKeywordTest2.suite ())
          ]

  fun init () =
      let
        val _ = Java.initialize["-Djava.class.path=."]

        val _ = JDK.static ()

        val _ = ArrayTest1.init ()
        val _ = MemberAccessTest1.init ()
        val _ = ObjectBasicsTest1.init ()
        val _ = ClassBasicsTest1.init ()
        val _ = ExceptionTest1.init ()
        val _ = MethodCallTest1.init ()
        val _ = RenameKeywordTest1.init ()
        val _ = RenameKeywordTest2.init ()
      in
        ()
      end

  fun test () =
      let
        val tests = suite ()
      in SMLUnit.TextUITestRunner.runTest {output = TextIO.stdOut} tests
      end

end
