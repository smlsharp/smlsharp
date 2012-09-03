use "./Reference1Testee.sml";

(*
 * test cases for handling reference parameter and return.
 *)
structure Reference1Tester =
struct

  structure A = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure T = Reference1Testee

  open AssertOLEValue
  open AssertDotNETValue

  (**********)

  (** pass [ref] int parameter.
   *)
  fun testPassIntRef1 () =
      let
        val obj = T.newReference1Testee ()
        val resultRef = ref (OLE.I4 2)
        val _ = A.assertEqualUnit (#addIntRef obj (1, resultRef))
        val _ = assertEqualVariant (OLE.I4 3) (!resultRef)
      in
        ()
      end

  (**
   * pass the same reference in two [ref] arguments.
   *)
  fun testPassIntRef2 () =
      let
        val obj = T.newReference1Testee ()
        val resultRef = ref (OLE.I4 2)
        val _ = A.assertEqualUnit (#divIntRef obj (6, resultRef, resultRef))
        val _ = assertEqualVariant (OLE.I4 3) (!resultRef)
      in
        ()
      end

  (**
   * pass [out] parameter.
   *)
  fun testPassIntOut1 () =
      let
        val obj = T.newReference1Testee ()
        val resultRef = ref (OLE.I4 0)
        val _ = A.assertEqualUnit (#mulIntOut obj (2, 3, resultRef))
        val _ = assertEqualVariant (OLE.I4 6) (!resultRef)
      in
        ()
      end

  (**
   * Passing a ref of empty (= VT_EMPTY | VT_BYREF) is not valid.
   * See http://msdn.microsoft.com/en-us/library/ms221627.aspx
   *)
  fun testPassIntOut2 () =
      let
        val obj = T.newReference1Testee ()
        val resultRef = ref (OLE.EMPTY)
        val _ =
            (#mulIntOut obj (2, 3, resultRef); A.fail "BYREF(EMPTY)")
            handle OLE.OLEError (OLE.ComSystemError _) => ()
      in
        ()
      end

  (** pass [ref] of object reference parameter.
   *)
  fun testPassObjectRef1 () =
      let
        val obj = T.newReference1Testee ()
        val obj1 = T.newReference1Testee ()
        val obj2 = T.newReference1Testee ()
        val dispatch1 = OLE.DISPATCH (#this obj1 ())
        val dispatch2 = OLE.DISPATCH (#this obj2 ())
        val resultRef = ref dispatch2
        val _ = A.assertEqualUnit (#copyObjectRef obj (dispatch1, resultRef))
        val _ = assertEqualVariant dispatch1 (!resultRef)
      in
        ()
      end

  (**
   * pass the different references in two [ref] arguments.
   *)
  fun testPassObjectRef2 () =
      let
        val obj = T.newReference1Testee ()
        val obj0 = T.newReference1Testee ()
        val obj1 = T.newReference1Testee ()
        val obj2 = T.newReference1Testee ()
        val dispatch0 = OLE.DISPATCH (#this obj0 ())
        val dispatch1 = OLE.DISPATCH (#this obj0 ())
        val dispatch2 = OLE.DISPATCH (#this obj2 ())
        val resultRef1 = ref dispatch1
        val resultRef2 = ref dispatch2
        (* copyObjectRef2 copies 1st argument to 2nd argument. 3rd is
         * unchanged. *)
        val _ = A.assertEqualUnit
                    (#copyObjectRef2 obj (dispatch0, resultRef1, resultRef2))
        val _ = assertEqualVariant dispatch0 (!resultRef1)
        val _ = assertEqualVariant dispatch2 (!resultRef2)
      in
        ()
      end

  (**
   * pass the same reference in two [ref] arguments.
   *)
  fun testPassObjectRef3 () =
      let
        val obj = T.newReference1Testee ()
        val obj0 = T.newReference1Testee ()
        val obj1 = T.newReference1Testee ()
        val dispatch0 = OLE.DISPATCH (#this obj0 ())
        val dispatch1 = OLE.DISPATCH (#this obj1 ())
        val resultRef1 = ref dispatch1
        (* copyObjectRef2 copies 1st argument to 2nd argument. 3rd is
         * unchanged. *)
        val _ = A.assertEqualUnit
                    (#copyObjectRef2 obj (dispatch0, resultRef1, resultRef1))
        val _ = assertEqualVariant dispatch0 (!resultRef1)
      in
        ()
      end

  (**
   * null reference is returned as EMPTY.
   *)
  fun testReceiveNull1 () =
      let
        val obj = T.newReference1Testee ()
        val _ = assertEqualVariant (OLE.EMPTY) (#returnNull obj ())
      in
        ()
      end

  (** pass a null dispatch as a null object reference. *)
  fun testPassNullObjectRef1 () =
      let
        val obj = T.newReference1Testee ()
        val _ = A.assertTrue(#isNullObject obj (OLE.DISPATCH OLE.NullDispatch))
        val _ = A.assertFalse (#isNullObject obj (OLE.DISPATCH (#this obj ())))
      in
        ()
      end

  (** pass EMPTY as a null object reference. *)
  fun testPassNullObjectRef2 () =
      let
        val obj = T.newReference1Testee ()
        val _ = A.assertTrue(#isNullObject obj (OLE.EMPTY))
      in
        ()
      end

  (** pass a null reference to [ref] of object reference parameter.
   *)
  fun testPassRefOfNullObjectRef1 () =
      let
        val obj = T.newReference1Testee ()
        val obj1 = T.newReference1Testee ()
        val dispatch1 = OLE.DISPATCH (#this obj1 ())
        val resultRef = ref (OLE.DISPATCH OLE.NullDispatch)
        val _ = A.assertEqualUnit (#copyObjectRef obj (dispatch1, resultRef))
        val _ = assertEqualVariant dispatch1 (!resultRef)
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
        ("testPassIntRef1", testPassIntRef1),
        ("testPassIntRef2", testPassIntRef2),
        ("testPassIntOut1", testPassIntOut1),
        ("testPassIntOut2", testPassIntOut2),
        ("testPassObjectRef1", testPassObjectRef1),
        ("testPassObjectRef2", testPassObjectRef2),
        ("testPassObjectRef3", testPassObjectRef3),
        ("testReceiveNull1", testReceiveNull1),
        ("testPassNullObjectRef1", testPassNullObjectRef1),
        ("testPassNullObjectRef2", testPassNullObjectRef2),
        ("testPassRefOfNullObjectRef1", testPassRefOfNullObjectRef1)
      ]

end