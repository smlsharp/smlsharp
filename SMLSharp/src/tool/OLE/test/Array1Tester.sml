use "./Array1Testee.sml";

structure Array1Tester =
struct

  structure A = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure T = Array1Testee

  open AssertOLEValue
  open AssertDotNETValue

  (**********)

  fun testZero1 () =
      let
        val obj = T.newArray1Testee ()

        val (safearray, dimensions) = #zero obj ()
        val _ = A.assertEqualIntList [0] dimensions
      in
        ()
      end

  fun testSingle1 () =
      let
        val obj = T.newArray1Testee ()

        val (safearray, dimensions) = #single obj ()
        val _ = A.assertEqualIntList [3] dimensions
        val _ = assertEqualint 0 (Array.sub (safearray, 0)) (* a[0] *)
        val _ = assertEqualint 1 (Array.sub (safearray, 1)) (* a[1] *)
        val _ = assertEqualint 2 (Array.sub (safearray, 2)) (* a[2] *)
      in
        ()
      end

  (**
   * COMinterop stores the elements of a safearray in column-major order.
   * The first dimension changes first, and the last dimension changes last.
   *)
  fun testMulti1 () =
      let
        val obj = T.newArray1Testee ()

        val (safearray, dimensions) = #multi2 obj ()
        val _ = A.assertEqualIntList [2, 3] dimensions
        val _ = assertEqualint 0 (Array.sub (safearray, 0)) (* a[0,0] *)
        val _ = assertEqualint 3 (Array.sub (safearray, 1)) (* a[1,0] *)
        val _ = assertEqualint 1 (Array.sub (safearray, 2)) (* a[0,1] *)
        val _ = assertEqualint 4 (Array.sub (safearray, 3)) (* a[1,1] *)
        val _ = assertEqualint 2 (Array.sub (safearray, 4)) (* a[0,2] *)
        val _ = assertEqualint 5 (Array.sub (safearray, 5)) (* a[1,2] *)
      in
        ()
      end

  fun testMulti2 () =
      let
        val obj = T.newArray1Testee ()

        val (safearray, dimensions) = #multi3 obj ()
        val _ = A.assertEqualIntList [10, 20, 30] dimensions

        (* access a[1,2,3] *)
        val _ = assertEqualint
                    (1 * (20 * 30) + 2 * (30) + 3)
                    (Array.sub (safearray, (3 * (10 * 20) + 2 * 10 + 1)))
      in
        ()
      end

  fun testMulti3 () =
      let
        val obj = T.newArray1Testee ()

        val safearray = #multi3 obj ()
        val _ =
            A.assertEqualIntList [10, 20, 30] (OLE.SafeArray.lengths safearray)

        val _ = assertEqualint
                    (1 * (20 * 30) + 2 * (30) + 3)
                    (OLE.SafeArray.sub (safearray, [1, 2, 3]))
      in
        ()
      end

  (******************************************)

  fun init () =
      let
      in
        ()
      end

  fun suite () =
      Test.labelTests
      [
        ("testZero1", testZero1),
        ("testSingle1", testSingle1),
        ("testMulti1", testMulti1),
        ("testMulti2", testMulti2),
        ("testMulti3", testMulti3)
      ]

end