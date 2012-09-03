use "./MethodCallTestee1.sml";
use "./MethodCallTestee1_Child.sml";

(**
 * TestCases for basic operations about Java class hierarchy.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure MethodCallTest1 =
struct

  structure A = SMLUnit.Assert
  structure Test = SMLUnit.Test
  structure JA = AssertJavaValue

  structure T = MethodCallTestee1
  structure T_Child = MethodCallTestee1_Child

  structure J = Java
  structure JV = Java.Value

  val $ = Java.call
  val $$ = Java.referenceOf

  (**********)

  fun testParamNumber () =
      let
        val obj = T.new()
        val _ = JA.assertEqualInt 123 ($obj#f_v())
        val _ = JA.assertEqualInt 123 ($obj#f_i 123)
        val _ = JA.assertEqualInt 123 ($obj#f_if (3, 12.0))
        val _ = JA.assertEqualInt 123 ($obj#f_dfi (3.0, 2.0, 1))
      in
        ()
      end

  (**********)

  fun testOverload () =
      let
        val obj = T.new()
        val _ = JA.assertEqualString (SOME"Z") ($obj#overload'Z true)
        val _ = JA.assertEqualString (SOME"B") ($obj#overload'B 0w1)
        val _ = JA.assertEqualString (SOME"C") ($obj#overload'C 0w12)
        val _ = JA.assertEqualString (SOME"S") ($obj#overload'S 123)
        val _ = JA.assertEqualString (SOME"I") ($obj#overload'I 1234)
        val _ = JA.assertEqualString (SOME"J") ($obj#overload'J 12345)
        val _ = JA.assertEqualString (SOME"F") ($obj#overload'F 1.23456)
        val _ = JA.assertEqualString (SOME"D") ($obj#overload'D 1.234567)
        val _ = JA.assertEqualString
                    (SOME"MethodCallTestee1") ($obj#overload'Object ($$obj))
        val _ = JA.assertEqualString (SOME"V") ($obj#overload ())
      in
        ()
      end

  (**********)

  fun testOverride () =
      let
        val parent = T.new ()
        val child = T_Child.new ()
        val cast_child = MethodCallTestee1($$child)
        val _ = JA.assertEqualString (SOME"parent") ($parent#override())
        val _ = JA.assertEqualString (SOME"child") ($child#override())
        val _ = JA.assertEqualString (SOME"child") ($cast_child#override())
      in
        ()
      end

  (******************************************)

  fun init () =
      let
        val _ = MethodCallTestee1.static()
        val _ = MethodCallTestee1_Child.static()
      in
        ()
      end

  fun suite () =
      Test.labelTests
      [
        ("testParamNumber", testParamNumber),
        ("testOverload", testOverload),
        ("testOverride", testOverride)
      ]

end;
