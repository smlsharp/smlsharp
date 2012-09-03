structure AssertDotNETValue =
struct

  structure OA = AssertOLEValue

  val assertEqualbyte = OA.assertEqualUI1
  val assertEqualsbyte = OA.assertEqualI1
  val assertEqualshort = OA.assertEqualI2
  val assertEqualushort = OA.assertEqualUI2
  val assertEqualint = OA.assertEqualI4
  val assertEqualuint = OA.assertEqualUI4
  val assertEquallong = OA.assertEqualI8
  val assertEqualulong = OA.assertEqualUI8
  val assertEqualfloat = OA.assertEqualR4
  val assertEqualdouble = OA.assertEqualR8
  val assertEqualdecimal = OA.assertEqualDECIMAL
(*
  val assertEqualchar = OA.assertEqualCHAR
*)
  val assertEqualstring = OA.assertEqualBSTR
  val assertEqualbool = OA.assertEqualBOOL
  val assertEqualobject = OA.assertEqualVARIANT
                          
end