use "./Property1Testee.sml";

(*
 * test cases for property accessor methods of .NET object.
 *)
structure Property1Tester =
struct

  structure A = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure T = Property1Testee

  open AssertOLEValue
  open AssertDotNETValue

  (**********)

  fun testWriteRead1 () =
      let
        val obj = T.newProperty1Testee ()
        val _ = A.assertEqualUnit () (#setproperty_I_RW obj (123))
        val _ = assertEqualint 123 (#getproperty_I_RW obj ())
      in
        ()
      end

  (** test case for property of object reference type.
   *)
  fun testWriteRead2 () =
      let
        val obj = T.newProperty1Testee ()
        val obj2 = T.newProperty1Testee ()
        val dispatch2 = OLE.DISPATCH(#this obj2())
        val _ = A.assertEqualUnit () (#setRefproperty_O_RW obj dispatch2)
        val _ = assertEqualobject dispatch2 (#getproperty_O_RW obj ())
      in
        ()
      end

  (** set null reference.
   *)
  fun testWriteRead3 () =
      let
        val obj = T.newProperty1Testee ()
        val dispatch2 = OLE.DISPATCH OLE.NullDispatch
        val _ = A.assertEqualUnit () (#setRefproperty_O_RW obj dispatch2)
        val _ = assertEqualobject OLE.EMPTY (#getproperty_O_RW obj ())
      in
        ()
      end

  fun testReadOnly1 () =
      let
        val obj = T.newProperty1Testee ()
        val _ = A.assertEqualUnit () (#set_I_R obj 123)
        val _ = assertEqualint 123 (#getproperty_I_R obj ())
      in
        ()
      end

  fun testWriteOnly1 () =
      let
        val obj = T.newProperty1Testee ()
        val _ = A.assertEqualUnit () (#setproperty_I_W obj (123))
        val _ = assertEqualint 123 (#get_I_W obj ())
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
        ("testWriteRead1", testWriteRead1),
        ("testWriteRead2", testWriteRead2),
        ("testWriteRead3", testWriteRead3),
        ("testReadOnly1", testReadOnly1),
        ("testWriteOnly1", testWriteOnly1)
      ]

end