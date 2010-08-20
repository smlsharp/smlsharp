use "./Reference2Testee.sml";

(**
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure Reference2Tester =
struct

  structure A = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure T = Reference2Testee

  open AssertOLEValue
  open AssertDotNETValue

  (**********)

  fun testMethod1 () =
      let
        val obj = T.newReference2Testee ()

        val (src, dst) = (0w1, 0w2)
        val (srcV, dstV) = (OLE.UI1 src, ref (OLE.UI1 dst))
        val _ = assertEqualbyte dst (#method_byte obj (src, dstV))
        val _ = assertEqualVariant srcV (!dstV)

        val (src, dst) = (1, 2)
        val (srcV, dstV) = (OLE.I1 src, ref (OLE.I1 dst))
        val _ = assertEqualsbyte dst (#method_sbyte obj (src, dstV))
        val _ = assertEqualVariant srcV (!dstV)

        val (src, dst) = (10, 20)
        val (srcV, dstV) = (OLE.I2 src, ref (OLE.I2 dst))
        val _ = assertEqualshort dst (#method_short obj (src, dstV))
        val _ = assertEqualVariant srcV (!dstV)

        val (src, dst) = (0w10, 0w20)
        val (srcV, dstV) = (OLE.UI2 src, ref (OLE.UI2 dst))
        val _ = assertEqualushort dst (#method_ushort obj (src, dstV))
        val _ = assertEqualVariant srcV (!dstV)

        val (src, dst) = (100, 200)
        val (srcV, dstV) = (OLE.I4 src, ref (OLE.I4 dst))
        val _ = assertEqualint dst (#method_int obj (src, dstV))
        val _ = assertEqualVariant srcV (!dstV)

        val (src, dst) = (0w100, 0w200)
        val (srcV, dstV) = (OLE.UI4 src, ref (OLE.UI4 dst))
        val _ = assertEqualuint dst (#method_uint obj (src, dstV))
        val _ = assertEqualVariant srcV (!dstV)

        val (src, dst) = (1000, 2000)
        val (srcV, dstV) = (OLE.I8 src, ref (OLE.I8 dst))
        val _ = assertEquallong dst (#method_long obj (src, dstV))
        val _ = assertEqualVariant srcV (!dstV)

        val (src, dst) = (1000, 200)
        val (srcV, dstV) = (OLE.UI8 src, ref (OLE.UI8 dst))
        val _ = assertEqualulong dst (#method_ulong obj (src, dstV))
        val _ = assertEqualVariant srcV (!dstV)

        val (src, dst) = (1.23, 2.34)
        val (srcV, dstV) = (OLE.R4 src, ref (OLE.R4 dst))
        val _ = assertEqualfloat dst (#method_float obj (src, dstV))
        val _ = assertEqualVariant srcV (!dstV)

        val (src, dst) = (12.3, 23.4)
        val (srcV, dstV) = (OLE.R8 src, ref (OLE.R8 dst))
        val _ = assertEqualdouble dst (#method_double obj (src, dstV))
        val _ = assertEqualVariant srcV (!dstV)

        val (src, dst) = ({scale = 0w0, value = 1}, {scale = 0w2, value = 3})
        val (srcV, dstV) = (OLE.DECIMAL src, ref (OLE.DECIMAL dst))
        val _ = assertEqualdecimal dst (#method_decimal obj (src, dstV))
        val _ = assertEqualVariant srcV (!dstV)

(*
        val _ = assertEqualchar 1 (#method_char obj 1)
*)
        val (src, dst) = (OLE.L "ABC", OLE.L "XYZ")
        val (srcV, dstV) = (OLE.BSTR src, ref (OLE.BSTR dst))
        val _ = assertEqualstring dst (#method_string obj (src, dstV))
        val _ = assertEqualVariant srcV (!dstV)

        val (src, dst) = (true, false)
        val (srcV, dstV) = (OLE.BOOL src, ref (OLE.BOOL dst))
        val _ = assertEqualbool dst (#method_bool obj (src, dstV))
        val _ = assertEqualVariant srcV (!dstV)

        val (src, dst) =
            (
              OLE.DISPATCH(#this (T.newReference2Testee()) ()),
              OLE.DISPATCH(#this (T.newReference2Testee()) ())
            )
        val (srcV, dstV) = (src, ref dst)
        val _ = assertEqualobject dst (#method_object obj (src, dstV))
        val _ = assertEqualVariant srcV (!dstV)

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
        ("testMethod1", testMethod1)
      ]

end