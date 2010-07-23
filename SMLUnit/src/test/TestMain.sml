(**
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure TestMain =
struct

  fun test () =
      (
        TestAssert.runTest ();
        TestTest.runTest ();
        TestTextUITestRunner.runTest ()
      )

end