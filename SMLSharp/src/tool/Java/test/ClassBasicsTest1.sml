use "./ClassBasicsTestee1.sml";
use "./ClassBasicsTestee1_Child.sml";
use "./ClassBasicsTestee1_NotChild.sml";

(**
 * TestCases for basic operations about Java class hierarchy.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure ClassBasicsTest1 =
struct

  structure A = SMLUnit.Assert
  structure Test = SMLUnit.Test
  structure JA = AssertJavaValue

  structure T = ClassBasicsTestee1
  structure T_Child = ClassBasicsTestee1_Child
  structure T_NotChild = ClassBasicsTestee1_NotChild

  structure J = Java
  structure JV = Java.Value

  val $ = Java.call
  val $$ = Java.referenceOf

  (**********)

  fun testIsInstance () =
      let
        val obj = T.new()
        val obj_child = T_Child.new()
        val obj_notchild = T_NotChild.new()
        val _ = A.assertTrue (T.isInstance ($$obj))
        val _ = A.assertTrue (T.isInstance ($$obj_child))
        val _ = A.assertFalse (T.isInstance ($$obj_notchild))
      in
        ()
      end

  (**********)

  fun testCast () =
      let
        val obj = T.new()
        val obj_child = T_Child.new()
        val obj_notchild = T_NotChild.new()
        (* self cast *)
        val _ = JA.assertEqualObject ($$obj) ($$(ClassBasicsTestee1($$obj)))
        (* up-cast *)
        val _ = JA.assertEqualObject
                    ($$obj_child) ($$(ClassBasicsTestee1($$obj_child)))
        val _ =
            (ClassBasicsTestee1 ($$obj_notchild); A.fail "illegal cast")
            handle J.ClassCastException => ()
        (* down-cast *)
        val obj_child_up = ClassBasicsTestee1 ($$obj_child)
        val _ = JA.assertEqualObject
                    ($$obj_child)
                    ($$(ClassBasicsTestee1_Child($$obj_child_up)))
        val _ =
            (ClassBasicsTestee1_Child ($$obj); A.fail "illegal cast")
            handle J.ClassCastException => ()
      in
        ()
      end
           
  (**********)

  fun testClass () =
      let
        val obj = T.new()
        val cls = $obj#getClass()
        val _ = JA.assertEqualObject cls (T.class())
      in
        ()
      end

  (******************************************)

  fun init () =
      let
        val _ = ClassBasicsTestee1.static()
        val _ = ClassBasicsTestee1_Child.static()
        val _ = ClassBasicsTestee1_NotChild.static()
      in
        ()
      end

  fun suite () =
      Test.labelTests
      [
        ("testIsInstance", testIsInstance),
        ("testCast", testCast),
        ("testClass", testClass)
      ]

end;
