(**
 * @author YAMATODANI Kiyoshi
 * @copyright (C) 2021 SML# Development Team.
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