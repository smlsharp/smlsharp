use "./DataTypes1Testee.sml";

(**
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure DataTypes1Tester =
struct

  structure A = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure T = DataTypes1Testee

  open AssertDotNETValue

  (**********)

  fun testMethod1 () =
      let
        val obj = T.newDataTypes1Testee ()
        val _ = assertEqualbyte 0w1 (#method_byte obj 0w1)
        val _ = assertEqualsbyte 1 (#method_sbyte obj 1)
        val _ = assertEqualsbyte ~1 (#method_sbyte obj ~1)
        val _ = assertEqualshort 10 (#method_short obj 10)
        val _ = assertEqualshort ~10 (#method_short obj ~10)
        val _ = assertEqualushort 0w10 (#method_ushort obj 0w10)
        val _ = assertEqualint 100 (#method_int obj 100)
        val _ = assertEqualint ~100 (#method_int obj ~100)
        val _ = assertEqualuint 0w100 (#method_uint obj 0w100)
        val _ = assertEquallong 1000 (#method_long obj 1000)
        val _ = assertEquallong ~1000 (#method_long obj ~1000)
        val _ = assertEqualulong 10000 (#method_ulong obj 10000)
        val _ = assertEqualfloat 1.23 (#method_float obj 1.23)
        val _ = assertEqualfloat ~1.23 (#method_float obj ~1.23)
        val _ = assertEqualdouble 12.3 (#method_double obj 12.3)
        val _ = assertEqualdouble ~12.3 (#method_double obj ~12.3)
        val _ = assertEqualdecimal
                    {scale = 0w0, value = 1}
                    (#method_decimal obj {scale = 0w0, value = 1})
        val _ = assertEqualdecimal
                    {scale = 0w0, value = ~1}
                    (#method_decimal obj {scale = 0w0, value = ~1})
(*
        val _ = assertEqualchar 1 (#method_char obj 1)
*)
        val _ =
            assertEqualstring (OLE.L "ABC") (#method_string obj (OLE.L "ABC"))
        val _ = assertEqualbool true (#method_bool obj true)
        val dispatch = OLE.DISPATCH(#this obj())
        val _ = assertEqualobject dispatch (#method_object obj dispatch)
      in
        ()
      end

  fun testToString1 () =
      let
        val obj = T.newDataTypes1Testee ()
        val _ = assertEqualstring (OLE.L"1") (#toString_byte obj 0w1)
        val _ = assertEqualstring (OLE.L"1") (#toString_sbyte obj 1)
        val _ = assertEqualstring (OLE.L"1") (#toString_short obj 1)
        val _ = assertEqualstring (OLE.L"1") (#toString_ushort obj 0w1)
        val _ = assertEqualstring (OLE.L"1") (#toString_int obj 1)
        val _ = assertEqualstring (OLE.L"1") (#toString_uint obj 0w1)
        val _ = assertEqualstring (OLE.L"1") (#toString_long obj 1)
        val _ = assertEqualstring (OLE.L"1") (#toString_ulong obj 1)
        val _ = assertEqualstring (OLE.L"1.23") (#toString_float obj 1.23)
        val _ = assertEqualstring (OLE.L"1.23") (#toString_double obj 1.23)

        val _ = assertEqualstring
                    (OLE.L"1") (#toString_decimal obj {scale = 0w0, value = 1})

(*
        val _ = assertEqualstring (OLE.L"1") (#toString_char obj 1)
*)
        val _ = assertEqualstring (OLE.L"A") (#toString_string obj (OLE.L"A"))
        val _ = assertEqualstring (OLE.L"True") (#toString_bool obj true)
        val dispatch = OLE.DISPATCH(#this obj())
        val _ =
            assertEqualstring
                (OLE.L"DataTypes1Testee") (#toString_object obj dispatch)
      in
        ()
      end

  fun testNullReference1 () =
      let
        val obj = T.newDataTypes1Testee ()

        (* Null object reference is marshalled to a variant EMPTY
         * when returned from .NET to COM.
         * http://msdn.microsoft.com/en-us/library/2x07fbw8(VS.80).aspx *)
        val _ =
            assertEqualobject
                OLE.EMPTY
                (#method_object obj (OLE.DISPATCH OLE.NullDispatch))
        val _ =
            assertEqualobject
                OLE.EMPTY
                (#method_object obj (OLE.UNKNOWN OLE.NullUnknown))
        val _ = A.assertFalse (OLE.isNullDispatch (#this obj ()))
        val _ = A.assertTrue (OLE.isNullDispatch OLE.NullDispatch)
      in
        ()
      end

  fun testShortMethod1 () =
      let
        val obj = T.newDataTypes1Testee ()
        val _ = assertEqualshort 0x7FFF (#method_short obj 0x7FFF)
        val _ = (#method_short obj 0x8000; A.fail "should raise Conversion")
                handle OLE.OLEError(OLE.Conversion _) => ()
        val _ = assertEqualshort ~0x8000 (#method_short obj ~0x8000)
        val _ = (#method_short obj ~0x8001; A.fail "should raise Conversion")
                handle OLE.OLEError(OLE.Conversion _) => ()
      in
        ()
      end

  fun testUshortMethod1 () =
      let
        val obj = T.newDataTypes1Testee ()
        val _ = assertEqualushort 0wxFFFF (#method_ushort obj 0wxFFFF)
        val _ = (#method_ushort obj 0wx10000; A.fail "should raise Conversion")
                handle OLE.OLEError(OLE.Conversion _) => ()
        val _ = assertEqualushort 0wx0 (#method_ushort obj 0wx0)
      in
        ()
      end

  fun testLongMethod1 () =
      let
        val obj = T.newDataTypes1Testee ()

        val _ = assertEqualstring (OLE.L"123") (#toString_long obj 123)
        val _ = assertEquallong 123 (#fromString_long obj (OLE.L"123"))
        val _ = assertEqualstring (OLE.L"-123") (#toString_long obj ~123)
        val _ = assertEquallong ~123 (#fromString_long obj (OLE.L"-123"))

        val _ =
            assertEqualstring
                (OLE.L"9223372036854775807")
                (#toString_long obj 0x7FFFFFFFFFFFFFFF)
        val _ =
            assertEquallong
                0x7FFFFFFFFFFFFFFF
                (#fromString_long obj (OLE.L"9223372036854775807"))
        val _ =
            assertEquallong
                0x7FFFFFFFFFFFFFFF
                (#method_long obj 0x7FFFFFFFFFFFFFFF)

        val _ =
            (#method_long obj 0x8000000000000000; A.fail "raise Conversion")
            handle OLE.OLEError(OLE.Conversion _) => ()
        val _ =
            assertEquallong
                ~0x8000000000000000
                (#method_long obj ~0x8000000000000000)
        val _ =
            (#method_long obj ~0x8000000000000001; A.fail "raise Conversion")
            handle OLE.OLEError(OLE.Conversion _) => ()
      in
        ()
      end

  fun testUlongMethod1 () =
      let
        val obj = T.newDataTypes1Testee ()

        val _ = assertEqualstring (OLE.L"123") (#toString_ulong obj 123)
        val _ = assertEquallong 123 (#fromString_ulong obj (OLE.L"123"))
        val _ = assertEqualstring (OLE.L"0") (#toString_ulong obj 0)
        val _ = assertEquallong 0 (#fromString_ulong obj (OLE.L"0"))

        val _ =
            assertEqualstring
                (OLE.L"18446744073709551615")
                (#toString_ulong obj 0xFFFFFFFFFFFFFFFF)
        val _ =
            assertEqualulong
                0xFFFFFFFFFFFFFFFF
                (#fromString_ulong obj (OLE.L"18446744073709551615"))
        val _ =
            assertEqualulong
                0xFFFFFFFFFFFFFFFF
                (#method_ulong obj 0xFFFFFFFFFFFFFFFF)

        val _ =
            (#method_long obj 0x10000000000000000; A.fail "raise Conversion")
            handle OLE.OLEError(OLE.Conversion _) => ()
      in
        ()
      end

  (* test for passing normal decimals.
   *)
  fun testDecimalMethod1 () =
      let
        val obj = T.newDataTypes1Testee ()

        val zero = {scale = 0w0, value = 0}
        val one = {scale = 0w0, value = 1}

        val _ = assertEqualdecimal zero (#method_decimal obj zero)
        val _ = assertEqualdecimal one (#method_decimal obj one)

        val dec1 = {scale = 0w1, value = 123}
        val _ = assertEqualstring (OLE.L"12.3") (#toString_decimal obj dec1)
        val _ = assertEqualdecimal dec1 (#fromString_decimal obj (OLE.L"12.3"))

        val dec2 = {scale = 0w2, value = 123}
        val _ = assertEqualstring (OLE.L"1.23") (#toString_decimal obj dec2)
        val _ = assertEqualdecimal dec2 (#fromString_decimal obj (OLE.L"1.23"))
      in
        ()
      end

  (* check whether the limits of scale and value of decimal are handled
   * correctly.
   *)
  fun testDecimalMethod2 () =
      let
        val obj = T.newDataTypes1Testee ()

        val minScale = 
            {scale = OLE.Decimal.MIN_SCALE, value = OLE.Decimal.MAX_VALUE}
        val maxScale = 
            {scale = OLE.Decimal.MAX_SCALE, value = OLE.Decimal.MAX_VALUE}
        val minValue = 
            {scale = OLE.Decimal.MIN_SCALE, value = OLE.Decimal.MIN_VALUE}
        val maxValue = 
            {scale = OLE.Decimal.MIN_SCALE, value = OLE.Decimal.MAX_VALUE}

        val _ = assertEqualdecimal minScale (#method_decimal obj minScale)
        val _ = assertEqualdecimal maxScale (#method_decimal obj maxScale)
        val _ = assertEqualdecimal minValue (#method_decimal obj minValue)
        val _ = assertEqualdecimal maxValue (#method_decimal obj maxValue)
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
        ("testMethod1", testMethod1),
        ("testToString1", testToString1),
        ("testNullReference1", testNullReference1),
        ("testShortMethod1", testShortMethod1),
        ("testUshortMethod1", testUshortMethod1),
        ("testLongMethod1", testLongMethod1),
        ("testUlongMethod1", testUlongMethod1),
        ("testDecimalMethod1", testDecimalMethod1),
        ("testDecimalMethod2", testDecimalMethod2)
      ]

end