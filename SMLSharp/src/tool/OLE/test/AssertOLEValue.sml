(**
 * assertion functions for types defined in OLE.
 * @copyright (c) 2010, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: AssertJavaValue.sml,v 1.1 2010/04/25 13:40:30 kiyoshiy Exp $
 *)
structure AssertOLEValue =
struct

  structure A = Assert

  structure UM = UnmanagedMemory
  structure F = SMLSharp.Finalizable

  val assertEqualInt32 = A.assertEqualByCompare Int32.compare Int32.toString 

  val assertEqualInt16 = assertEqualInt32

  val assertEqualReal32 = A.assertEqual Real32.== Real32.toString 

  val assertEqualReal64 = A.assertEqual Real64.== Real64.toString 

  val assertEqualWord16 = A.assertEqualWord32

  val assertEqualIntInf = A.assertEqualByCompare IntInf.compare IntInf.toString

  val assertEqualInt64 = assertEqualIntInf

  val assertEqualWord64 = assertEqualInt64

  fun assertEqualARRAY assertEqualElement x y = 
      A.assertEqual2Tuple
          (A.assertEqualArray assertEqualElement, A.assertEqualIntList)
          x y

  (**********)

  val assertEqualI2 = assertEqualInt16

  val assertEqualI4 = assertEqualInt32

  val assertEqualR4 = assertEqualReal32

  val assertEqualR8 = assertEqualReal64

  val assertEqualBSTR =
      A.assertEqualByCompare
          UTF16LECodec.String.compare
          (fn bstr => "\"" ^ UTF16LECodec.String.toAsciiString bstr ^ "\"")

  fun assertEqualDISPATCH (x : OLE.Dispatch) (y : OLE.Dispatch) =
      let
        val addressX = F.getValue (#this x)
        val addressY = F.getValue (#this y)
      in
        A.assertEqualWord32
            (UM.addressToWord addressX)
            (UM.addressToWord addressY);
        x
      end

  val assertEqualERROR = assertEqualInt32

  val assertEqualBOOL = A.assertEqualBool

  fun assertEqualUNKNOWN (x : OLE.Unknown) (y : OLE.Unknown) =
      let
        val addressX = F.getValue (#this x)
        val addressY = F.getValue (#this y)
      in
        A.assertEqualWord32
            (UM.addressToWord addressX)
            (UM.addressToWord addressY);
        x
      end

  val assertEqualDECIMAL =
      A.assertEqualByCompare OLE.Decimal.compare OLE.Decimal.toString

(* defined below.
  val assertEqualVARIANT = 
*)

  val assertEqualI1 = assertEqualInt32

  val assertEqualUI1 = A.assertEqualWord8

  val assertEqualUI2 = assertEqualWord16

  val assertEqualUI4 = A.assertEqualWord32

  val assertEqualI8 = assertEqualInt64

  val assertEqualUI8 = assertEqualWord64

  val assertEqualINT = assertEqualInt32

  val assertEqualUINT = A.assertEqualWord32

  fun assertEqualVARIANT x y = assertEqualVariant x y
                               
  and assertEqualBYREF x y = assertEqualVariant x y
                             
  and assertEqualBYREFOUT x y = A.assertSameRef x y

  and assertEqualI2ARRAY x y = assertEqualARRAY assertEqualI2 x y
  and assertEqualI4ARRAY x y = assertEqualARRAY assertEqualI4 x y
  and assertEqualR4ARRAY x y = assertEqualARRAY assertEqualR4 x y
  and assertEqualR8ARRAY x y = assertEqualARRAY assertEqualR8 x y
  and assertEqualBSTRARRAY x y = assertEqualARRAY assertEqualBSTR x y
  and assertEqualDISPATCHARRAY x y = assertEqualARRAY assertEqualDISPATCH x y
  and assertEqualERRORARRAY x y = assertEqualARRAY assertEqualERROR x y
  and assertEqualBOOLARRAY x y = assertEqualARRAY assertEqualBOOL x y
  and assertEqualVARIANTARRAY x y = assertEqualARRAY assertEqualVARIANT x y
  and assertEqualUNKNOWNARRAY x y = assertEqualARRAY assertEqualUNKNOWN x y
  and assertEqualDECIMALARRAY x y = assertEqualARRAY assertEqualDECIMAL x y
  and assertEqualI1ARRAY x y = assertEqualARRAY assertEqualI1 x y
  and assertEqualUI1ARRAY x y = assertEqualARRAY assertEqualUI1 x y
  and assertEqualUI2ARRAY x y = assertEqualARRAY assertEqualUI2 x y
  and assertEqualUI4ARRAY x y = assertEqualARRAY assertEqualUI4 x y
  and assertEqualI8ARRAY x y = assertEqualARRAY assertEqualI8 x y
  and assertEqualUI8ARRAY x y = assertEqualARRAY assertEqualUI8 x y
  and assertEqualINTARRAY x y = assertEqualARRAY assertEqualINT x y
  and assertEqualUINTARRAY x y = assertEqualARRAY assertEqualUINT x y

  and assertEqualVariant expected actual =
      case (expected, actual) of
        (OLE.EMPTY, OLE.EMPTY) => actual
      | (OLE.I2 x, OLE.I2 y) => (assertEqualI2 x y; actual)
      | (OLE.I4 x, OLE.I4 y) => (assertEqualI4 x y; actual)
      | (OLE.R4 x, OLE.R4 y) => (assertEqualR4 x y; actual)
      | (OLE.R8 x, OLE.R8 y) => (assertEqualR8 x y; actual)
      | (OLE.BSTR x, OLE.BSTR y) => (assertEqualBSTR x y; actual)
      | (OLE.DISPATCH x, OLE.DISPATCH y) => (assertEqualDISPATCH x y; actual)
      | (OLE.ERROR x, OLE.ERROR y) => (assertEqualERROR x y; actual)
      | (OLE.BOOL x, OLE.BOOL y) => (assertEqualBOOL x y; actual)
      | (OLE.VARIANT x, OLE.VARIANT y) => (assertEqualVARIANT x y; actual)
      | (OLE.UNKNOWN x, OLE.UNKNOWN y) => (assertEqualUNKNOWN x y; actual)
      | (OLE.DECIMAL x, OLE.DECIMAL y) => (assertEqualDECIMAL x y; actual)
      | (OLE.I1 x, OLE.I1 y) => (assertEqualI1 x y; actual)
      | (OLE.UI1 x, OLE.UI1 y) => (assertEqualUI1 x y; actual)
      | (OLE.UI2 x, OLE.UI2 y) => (assertEqualUI2 x y; actual)
      | (OLE.UI4 x, OLE.UI4 y) => (assertEqualUI4 x y; actual)
      | (OLE.I8 x, OLE.I8 y) => (assertEqualI8 x y; actual)
      | (OLE.UI8 x, OLE.UI8 y) => (assertEqualUI8 x y; actual)
      | (OLE.INT x, OLE.INT y) => (assertEqualINT x y; actual)
      | (OLE.UINT x, OLE.UINT y) => (assertEqualUINT x y; actual)
      | (OLE.BYREF x, OLE.BYREF y) => (assertEqualBYREF x y; actual)
      | (OLE.BYREFOUT x, OLE.BYREFOUT y) => (assertEqualBYREFOUT x y; actual)
      | (OLE.I4ARRAY x, OLE.I4ARRAY y) => (assertEqualI4ARRAY x y; actual)
      | (OLE.VARIANTARRAY x, OLE.VARIANTARRAY y) =>
        (assertEqualVARIANTARRAY x y; actual)
      | _ =>
        A.fail
            ("Variant type mismatch:expected = ["
             ^ OLE.variantToString expected ^ "], \
             \actual = [" ^ OLE.variantToString actual ^ "]")

end;