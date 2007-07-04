structure TestMain =
struct

  fun test () =
      (
        TestAssert.runTest ();
        TestTest.runTest ();
        TestTextUITestRunner.runTest ()
      )

end