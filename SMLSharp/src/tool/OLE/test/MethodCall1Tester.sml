use "./MethodCall1Testee.sml";

(**
 * test cases for arity and co-arity of COM object method.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure MethodCall1Tester =
struct

  structure A = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure T = MethodCall1Testee

  open AssertOLEValue
  open AssertDotNETValue

  (**********)

  fun testArity1 () =
      let
        val obj = T.newMethodCall1Testee ()
        val _ = assertEqualI4 3 (#method_II_I obj (1, 2))
        val _ = assertEqualI4 3 (#method_ID_I obj (1, 2.34))
        val _ = assertEqualI4 3 (#method_DI_I obj (2.34, 1))
        val _ = assertEqualI4 8 (#method_DIB_I obj (2.34, 1, 0w5))
        val _ = assertEqualI4 8 (#method_BDI_I obj (0w5, 2.34, 1))
        val _ = assertEqualI4 8 (#method_IBD_I obj (1, 0w5, 2.34))
      in
        ()
      end

  fun testCoArity1 () =
      let
        val obj = T.newMethodCall1Testee ()
        val _ = A.assertEqualUnit () (#method_V_V obj ())
        val _ = A.assertEqualUnit () (#method_I_V obj (123))
        val _ = A.assertEqualUnit () (#method_II_V obj (123, 456))
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
        ("testArity1", testArity1),
        ("testCoArity1", testCoArity1)
      ]

end