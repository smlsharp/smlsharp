use "./ArrayTestee1.sml";

(**
 * TestCases for JavaArray structure.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure ArrayTest1 =
struct

  structure Assert = AssertJavaValue
  structure Test = SMLUnit.Test

  structure T = ArrayTestee1
  structure A = Java.Array

  (**********)

  fun testBooleanArray () =
      let
        val ai = A.NewBooleanArray 10

        val v = true
        val _ = A.updateBooleanArray (ai, 0, v)
        val xi = A.subBooleanArray (ai, 0)
        val _ = Assert.assertEqualBoolean v xi

        val v = false
        val _ = T.updateBooleans(ai, 1, v)
        val xi = T.subBooleans(ai, 1)
        val _ = Assert.assertEqualBoolean v xi

        val v = true
        val _ = A.updateBooleanArray (ai, 2, v)
        val xi = T.subBooleans(ai, 2)
        val _ = Assert.assertEqualBoolean v xi

        val v = false
        val _ = T.updateBooleans(ai, 3, v)
        val xi = A.subBooleanArray (ai, 3)
        val _ = Assert.assertEqualBoolean v xi
      in
        ()
      end

  (**********)

  fun testByteArray () =
      let
        val ai = A.NewByteArray 10

        val v = 0w12
        val _ = A.updateByteArray (ai, 0, v)
        val xi = A.subByteArray (ai, 0)
        val _ = Assert.assertEqualByte v xi

        val v = 0w23
        val _ = T.updateBytes(ai, 1, v)
        val xi = T.subBytes(ai, 1)
        val _ = Assert.assertEqualByte v xi

        val v = 0w34
        val _ = A.updateByteArray (ai, 2, v)
        val xi = T.subBytes(ai, 2)
        val _ = Assert.assertEqualByte v xi

        val v = 0w45
        val _ = T.updateBytes(ai, 3, v)
        val xi = A.subByteArray (ai, 3)
        val _ = Assert.assertEqualByte v xi
      in
        ()
      end

  (**********)

  val ordw = Word.fromInt o Char.ord
  fun testCharArray () =
      let
        val ai = A.NewCharArray 10

        val v = ordw #"A"
        val _ = A.updateCharArray (ai, 0, v)
        val xi = A.subCharArray (ai, 0)
        val _ = Assert.assertEqualChar v xi

        val v = ordw #"B"
        val _ = T.updateChars(ai, 1, v)
        val xi = T.subChars(ai, 1)
        val _ = Assert.assertEqualChar v xi

        val v = ordw #"C"
        val _ = A.updateCharArray (ai, 2, v)
        val xi = T.subChars(ai, 2)
        val _ = Assert.assertEqualChar v xi

        val v = ordw #"D"
        val _ = T.updateChars(ai, 3, v)
        val xi = A.subCharArray (ai, 3)
        val _ = Assert.assertEqualChar v xi
      in
        ()
      end

  (**********)

  fun testShortArray () =
      let
        val ai = A.NewShortArray 10

        val v = 123
        val _ = A.updateShortArray (ai, 0, v)
        val xi = A.subShortArray (ai, 0)
        val _ = Assert.assertEqualShort v xi

        val v = 234
        val _ = T.updateShorts(ai, 1, v)
        val xi = T.subShorts(ai, 1)
        val _ = Assert.assertEqualShort v xi

        val v = 345
        val _ = A.updateShortArray (ai, 2, v)
        val xi = T.subShorts(ai, 2)
        val _ = Assert.assertEqualShort v xi

        val v = 456
        val _ = T.updateShorts(ai, 3, v)
        val xi = A.subShortArray (ai, 3)
        val _ = Assert.assertEqualShort v xi
      in
        ()
      end

  (**********)

  fun testIntArray () =
      let
        val ai = A.NewIntArray 10

        val v = 123
        val _ = A.updateIntArray (ai, 0, v)
        val xi = A.subIntArray (ai, 0)
        val _ = Assert.assertEqualInt v xi

        val v = 234
        val _ = T.updateInts(ai, 1, v)
        val xi = T.subInts(ai, 1)
        val _ = Assert.assertEqualInt v xi

        val v = 345
        val _ = A.updateIntArray (ai, 2, v)
        val xi = T.subInts(ai, 2)
        val _ = Assert.assertEqualInt v xi

        val v = 456
        val _ = T.updateInts(ai, 3, v)
        val xi = A.subIntArray (ai, 3)
        val _ = Assert.assertEqualInt v xi
      in
        ()
      end

  (**********)

  fun testLongArray () =
      let
        val ai = A.NewLongArray 10

        val v = IntInf.fromInt 123
        val _ = A.updateLongArray (ai, 0, v)
        val xi = A.subLongArray (ai, 0)
        val _ = Assert.assertEqualLong v xi
(*
        val v = IntInf.fromInt 234
        val _ = T.updateLongs(ai, 1, v)
        val xi = T.subLongs(ai, 1)
        val _ = Assert.assertEqualLong v xi

        val v = IntInf.fromInt 345
        val _ = A.updateLongArray (ai, 2, v)
        val xi = T.subLongs(ai, 2)
        val _ = Assert.assertEqualLong v xi
*)
        val v = IntInf.fromInt 456
        val _ = T.updateLongs(ai, 3, v)
        val xi = A.subLongArray (ai, 3)
        val _ = Assert.assertEqualLong v xi
      in
        ()
      end

  (**********)

  fun testFloatArray () =
      let
        val af = A.NewFloatArray 10

        val v = 1.23
        val _ = A.updateFloatArray (af, 0, v)
        val xf = A.subFloatArray (af, 0)
        val _ = Assert.assertEqualFloat v xf
(*
        val v = 2.34
        val _ = T.updateFloats(af, 1, v)
        val xf = T.subFloats(af, 1)
        val _ = Assert.assertEqualFloat v xf

        val v = 3.45
        val _ = A.updateFloatArray (af, 2, v)
        val xf = T.subFloats(af, 2)
        val _ = Assert.assertEqualFloat v xf
*)
        val v = 4.56
        val _ = T.updateFloats(af, 3, v)
        val xf = A.subFloatArray (af, 3)
        val _ = Assert.assertEqualFloat v xf
      in
        ()
      end

  (**********)

  fun testDoubleArray () =
      let
        val ad = A.NewDoubleArray 10

        val v = 1.23
        val _ = A.updateDoubleArray (ad, 0, v)
        val xd = A.subDoubleArray (ad, 0)
        val _ = Assert.assertEqualDouble v xd

        val v = 2.34
        val _ = T.updateDoubles(ad, 1, v)
        val xd = T.subDoubles(ad, 1)
        val _ = Assert.assertEqualDouble v xd

        val v = 3.45
        val _ = A.updateDoubleArray (ad, 2, v)
        val xd = T.subDoubles(ad, 2)
        val _ = Assert.assertEqualDouble v xd

        val v = 4.56
        val _ = T.updateDoubles(ad, 3, v)
        val xd = A.subDoubleArray (ad, 3)
        val _ = Assert.assertEqualDouble v xd
      in
        ()
      end

  (**********)

  local
    structure JString = JDK.java.lang.String
    val $$ = Java.referenceOf
  in
  fun testObjectArray () =
      let
        val class = JString.class ()
        val initialValue = Java.null
        val ad = A.NewObjectArray (10, class, initialValue)

        val v = JString.new ()
        val _ = A.updateObjectArray (ad, 0, $$v)
        val xd = A.subObjectArray (ad, 0)
        val _ = Assert.assertEqualObject ($$v) xd

        val v = JString.new ()
        val _ = T.updateObjects(ad, 1, $$v)
        val xd = T.subObjects(ad, 1)
        val _ = Assert.assertEqualObject ($$v) xd

        val v = JString.new ()
        val _ = A.updateObjectArray (ad, 2, $$v)
        val xd = T.subObjects(ad, 2)
        val _ = Assert.assertEqualObject ($$v) xd

        val v = JString.new ()
        val _ = T.updateObjects(ad, 3, $$v)
        val xd = A.subObjectArray (ad, 3)
        val _ = Assert.assertEqualObject ($$v) xd
      in
        ()
      end
  end

  (**********)

  (******************************************)

  fun init () =
      let
        val _ = ArrayTestee1.static()
      in
        ()
      end

  fun suite () =
      Test.labelTests
      [
        ("booleanArray", testBooleanArray),
        ("byteArray", testByteArray),
        ("charArray", testCharArray),
        ("shortArray", testShortArray),
        ("intArray", testIntArray),
        ("longArray", testLongArray),
        ("floatArray", testFloatArray),
        ("doubleArray", testDoubleArray),
        ("objectArray", testObjectArray)
      ]

end;
