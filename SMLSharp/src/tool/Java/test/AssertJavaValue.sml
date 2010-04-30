(**
 * assertion functions for types defined in JavaValue.
 * @copyright (c) 2010, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: AssertJavaValue.sml,v 1.1 2010/04/25 13:40:30 kiyoshiy Exp $
 *)
structure AssertJavaValue =
struct

  structure A = Assert

  val assertEqualBoolean = A.assertEqualBool

  val assertEqualByte = A.assertEqualWord8

  val assertEqualChar = A.assertEqualWord

  val assertEqualShort = A.assertEqualInt

  val assertEqualInt = A.assertEqualInt

  val assertEqualLong =
      A.assertEqual (fn (x : IntInf.int, y) => x = y) IntInf.toString

  (* FIXME: replace Float_toString to Real32.toString,
      Float_equal to Real32.== *)
  val assertEqualFloat = A.assertEqual Float_equal Float_toString

  val assertEqualDouble = A.assertEqualReal

  local
    structure JString = JDK.java.lang.String
  in
  val assertEqualObject =
      A.assertEqual
          (fn (x, y) => Java.isSameObject (x, y))
          (fn obj =>
              Option.getOpt(JString.valueOf'Object obj, "NULL"))
  end

  val assertEqualString = A.assertEqualOption A.assertEqualString

  val assertEqualVoid = A.assertEqualUnit

end;