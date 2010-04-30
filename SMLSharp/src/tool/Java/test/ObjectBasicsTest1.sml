use "./ObjectBasicsTestee1.sml";

(**
 * TestCases for basic operations on Java object.
 *)
structure ObjectBasicsTest1 =
struct

  structure A = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure T = ObjectBasicsTestee1

  structure J = Java
  structure JA = Java.Array
  structure JV = Java.Value

  val $ = Java.call
  val $$ = Java.referenceOf

  (**********)

  fun testIsNull () =
      let
        val obj = T.new()
        val _ = A.assertTrue (J.isNull JV.null)
        val _ = A.assertTrue (J.isNull ($obj#returnNull ()))
        val _ = A.assertFalse (J.isNull ($obj#returnNonNull ()))
      in
        ()
      end
           
  (**********)

  fun testIsSameObject () =
      let
        val obj1 = T.new()
        val obj2 = T.new()
        val _ = A.assertTrue (J.isSameObject ($$obj1, $$obj1))
        val _ = A.assertFalse (J.isSameObject ($$obj1, $$obj2))
      in
        ()
      end
           
  (**********)

  (******************************************)

  fun init () =
      let
        val _ = ObjectBasicsTestee1.static()
      in
        ()
      end

  fun suite () =
      Test.labelTests
      [
        ("testIsNull", testIsNull),
        ("testIsSameObject", testIsSameObject)
      ]

end;
