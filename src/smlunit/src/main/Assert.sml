(**
 * Implementation of assert functions.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: Assert.sml,v 1.4 2007/05/20 05:45:07 kiyoshiy Exp $
 *)
structure Assert =
struct

  (***************************************************************************)

  type 'a assertEqual = 'a -> 'a -> unit

  type 'a valueFormatter = 'a -> string

  datatype failure =
           GeneralFailure of string
         | NotEqualFailure of string * string

  (***************************************************************************)

  exception Fail of failure

  (***************************************************************************)

  fun fail message = raise (Fail (GeneralFailure message))

  fun failByNotEqual (expected, actual) =
      raise Fail(NotEqualFailure (expected, actual))

  fun assert message true = ()
    | assert message false = fail message

  fun assertEqual comparator valueFormatter expected actual =
      if comparator (expected, actual)
      then ()
      else
        let
          val expectedText = valueFormatter expected
          val actualText = valueFormatter actual
        in
          failByNotEqual (expectedText, actualText)
        end

  fun assertEqualByCompare comparator =
      assertEqual (fn pair => comparator pair = EQUAL)

  fun assertEqualAlternatives assert [expected] actual = assert expected actual
    | assertEqualAlternatives assert (expected :: expecteds) actual =
      (assert expected actual
       handle Fail _ => assertEqualAlternatives assert expecteds actual)
    | assertEqualAlternatives assert [] actual =
      fail "assertEqualAlternatives expects non-empty list"

  fun convertAssertEqual convert assert expected actual =
      assert (convert expected) (convert actual)

  (****************************************)

  (* assertions specialized for every Top-level types *)

  fun assertEqualUnit () () = ()

  fun assertEqualInt expected actual =
      assertEqualByCompare Int.compare Int.toString expected actual

  fun assertEqualWord  expected actual = 
      assertEqualByCompare Word.compare Word.toString expected actual

  fun assertEqualWord8 expected actual = 
      assertEqualByCompare Word8.compare Word8.toString expected actual

  fun assertEqualWord32 expected actual =
      assertEqualByCompare Word32.compare Word32.toString expected actual

  fun assertEqualReal expected actual =
      case (Real.isNan expected, Real.isNan actual)
       of (true, true) => ()
        | (false, false) =>
          assertEqualByCompare Real.compare Real.toString expected actual
        | _ => failByNotEqual (Real.toString expected, Real.toString actual)

  fun assertEqualReal_epsilon epsilon expected actual =
      case (Real.isNan expected, Real.isNan actual)
       of (true, true) => ()
        | (false, false) =>
          if expected - epsilon <= actual andalso actual <= expected + epsilon
          then ()
          else failByNotEqual (Real.toString expected, Real.toString actual)
        | _ => failByNotEqual (Real.toString expected, Real.toString actual)

  fun assertEqualChar expected actual = 
      assertEqualByCompare Char.compare Char.toString expected actual

  fun assertEqualString expected actual = 
      assertEqualByCompare
          String.compare (fn s => "\"" ^ s ^ "\"") expected actual

  fun assertEqualSubstring expected actual = 
      assertEqualByCompare Substring.compare Substring.string expected actual

  fun assertEqualExceptionName expected actual =
      assertEqualByCompare
       String.compare
       (fn s => s)
       (exnName expected)
       (exnName actual)

(*
  fun assertEqualExceptionMessage expected actual = 
      (assertEqualByCompare
       String.compare
       (fn s => s)
       ""
       (exnMessage expected)
       (exnMessage actual);
       actual)
*)

  (****************************************)

  (**
   * asserts that the locations which two references point hold the same value.
   *)
  fun assertEqualRef assertReferred expected actual =
      if expected = actual
      then ()
      else (assertReferred (! expected) (! actual))
           handle Fail(NotEqualFailure (expected, actual)) =>
                  failByNotEqual
                      ("ref(" ^ expected ^ ")", "ref(" ^ actual ^ ")")

  (**
   * asserts that two references point to the same location
   *)
  fun assertSameRef expected actual =
      (assertEqual
       (fn (expected as ref _, actual) => expected = actual)
       (fn reference => "ref ??")
       expected
       actual)
      handle Fail(NotEqualFailure (expected, actual)) =>
             failByNotEqual ("ref(" ^ expected ^ ")", "ref(" ^ actual ^ ")")

  (****************************************)

  fun assertEqualBool (expected : bool) actual =
      assertEqual
      (fn (expected, actual) => expected = actual)
      (fn true => "true" | false => "false")
      expected
      actual
  fun assertTrue actual = assertEqualBool true actual
  fun assertFalse actual = assertEqualBool false actual

  (****************************************)

  fun assertEqualOption assertHolded expected actual =
      case (expected, actual) of
          (NONE, NONE) => ()
        | (NONE, SOME _) => failByNotEqual ("NONE", "SOME(?)")
        | (SOME _, NONE) => failByNotEqual ("SOME(?)", "NONE")
        | (SOME expectedValue, SOME actualValue) =>
          (assertHolded expectedValue actualValue)
          handle Fail (GeneralFailure message) =>
                 fail ("both was SOME_, but contents differ:" ^ message)
               | Fail (NotEqualFailure (expected, actual)) =>
                 failByNotEqual
                     ("SOME(" ^ expected ^ ")", "SOME(" ^ actual ^ ")")

  val assertEqualIntOption = assertEqualOption assertEqualInt

  val assertEqualWordOption = assertEqualOption assertEqualWord

  val assertEqualWord8Option = assertEqualOption assertEqualWord8

  val assertEqualWord32Option = assertEqualOption assertEqualWord32

  val assertEqualRealOption = assertEqualOption assertEqualReal

  val assertEqualCharOption = assertEqualOption assertEqualChar

  val assertEqualStringOption = assertEqualOption assertEqualString

  val assertEqualSubstringOption = assertEqualOption assertEqualSubstring

  fun assertSome actual =
      if isSome actual then () else fail "SOME expected."
  fun assertNone actual =
      if not (isSome actual) then () else fail "NONE expected."

  (****************************************)

  fun assertEqualOrder expected actual =
      assertEqual
      (fn (expected, actual) => expected = actual)
      (fn LESS => "LESS"
        | EQUAL => "EQUAL"
        | GREATER => "GREATER")
      expected
      actual

  (****************************************)

  local
  fun assertTupleElement index assertElement expectedValue actualValue =
      assertElement expectedValue actualValue
      handle Fail(NotEqualFailure (expected, actual)) =>
             let
               val expectedString =
                   "#" ^ Int.toString index ^ " = " ^ expected
               val actualString =
                   "#" ^ Int.toString index ^ " = " ^ actual
             in failByNotEqual (expectedString, actualString)
             end
  in
  fun assertEqual2Tuple
      (assert1, assert2)
      (expected1, expected2)
      (actual1, actual2) =
      (
        assertTupleElement 1 assert1 expected1 actual1;
        assertTupleElement 2 assert2 expected2 actual2
      )

  fun assertEqual3Tuple
      (assert1, assert2, assert3)
      (expected1, expected2, expected3)
      (actual1, actual2, actual3) =
      (
        assertTupleElement 1 assert1 expected1 actual1;
        assertTupleElement 2 assert2 expected2 actual2;
        assertTupleElement 3 assert3 expected3 actual3
      )

  fun assertEqual4Tuple
      (assert1, assert2, assert3, assert4)
      (expected1, expected2, expected3, expected4)
      (actual1, actual2, actual3, actual4) =
      (
        assertTupleElement 1 assert1 expected1 actual1;
        assertTupleElement 2 assert2 expected2 actual2;
        assertTupleElement 3 assert3 expected3 actual3;
        assertTupleElement 4 assert4 expected4 actual4
      )

  fun assertEqual5Tuple
      (assert1, assert2, assert3, assert4, assert5)
      (expected1, expected2, expected3, expected4, expected5)
      (actual1, actual2, actual3, actual4, actual5) =
      (
        assertTupleElement 1 assert1 expected1 actual1;
        assertTupleElement 2 assert2 expected2 actual2;
        assertTupleElement 3 assert3 expected3 actual3;
        assertTupleElement 4 assert4 expected4 actual4;
        assertTupleElement 5 assert5 expected5 actual5
      )

  fun assertEqual6Tuple
      (assert1, assert2, assert3, assert4, assert5, assert6)
      (expected1, expected2, expected3, expected4, expected5, expected6)
      (actual1, actual2, actual3, actual4, actual5, actual6) =
      (
        assertTupleElement 1 assert1 expected1 actual1;
        assertTupleElement 2 assert2 expected2 actual2;
        assertTupleElement 3 assert3 expected3 actual3;
        assertTupleElement 4 assert4 expected4 actual4;
        assertTupleElement 5 assert5 expected5 actual5;
        assertTupleElement 6 assert6 expected6 actual6
      )

  fun assertEqual7Tuple
      (assert1, assert2, assert3, assert4, assert5, assert6, assert7)
      (
        expected1,
        expected2,
        expected3,
        expected4,
        expected5,
        expected6,
        expected7
      )
      (actual1, actual2, actual3, actual4, actual5, actual6, actual7) =
      (
        assertTupleElement 1 assert1 expected1 actual1;
        assertTupleElement 2 assert2 expected2 actual2;
        assertTupleElement 3 assert3 expected3 actual3;
        assertTupleElement 4 assert4 expected4 actual4;
        assertTupleElement 5 assert5 expected5 actual5;
        assertTupleElement 6 assert6 expected6 actual6;
        assertTupleElement 7 assert7 expected7 actual7
      )

  fun assertEqual8Tuple
      (assert1, assert2, assert3, assert4, assert5, assert6, assert7, assert8)
      (
        expected1,
        expected2,
        expected3,
        expected4,
        expected5,
        expected6,
        expected7,
        expected8
      )
      (actual1, actual2, actual3, actual4, actual5, actual6, actual7, actual8)=
      (
        assertTupleElement 1 assert1 expected1 actual1;
        assertTupleElement 2 assert2 expected2 actual2;
        assertTupleElement 3 assert3 expected3 actual3;
        assertTupleElement 4 assert4 expected4 actual4;
        assertTupleElement 5 assert5 expected5 actual5;
        assertTupleElement 6 assert6 expected6 actual6;
        assertTupleElement 7 assert7 expected7 actual7;
        assertTupleElement 8 assert8 expected8 actual8
      )

  fun assertEqual9Tuple
      (
        assert1,
        assert2,
        assert3,
        assert4,
        assert5,
        assert6,
        assert7,
        assert8,
        assert9
      )
      (
        expected1,
        expected2,
        expected3,
        expected4,
        expected5,
        expected6,
        expected7,
        expected8,
        expected9
      )
      (
        actual1,
        actual2,
        actual3,
        actual4,
        actual5,
        actual6,
        actual7,
        actual8,
        actual9
      ) =
      (
        assertTupleElement 1 assert1 expected1 actual1;
        assertTupleElement 2 assert2 expected2 actual2;
        assertTupleElement 3 assert3 expected3 actual3;
        assertTupleElement 4 assert4 expected4 actual4;
        assertTupleElement 5 assert5 expected5 actual5;
        assertTupleElement 6 assert6 expected6 actual6;
        assertTupleElement 7 assert7 expected7 actual7;
        assertTupleElement 8 assert8 expected8 actual8;
        assertTupleElement 9 assert9 expected9 actual9
      )

  fun assertEqual10Tuple
      (
        assert1,
        assert2,
        assert3,
        assert4,
        assert5,
        assert6,
        assert7,
        assert8,
        assert9,
        assert10
      )
      (
        expected1,
        expected2,
        expected3,
        expected4,
        expected5,
        expected6,
        expected7,
        expected8,
        expected9,
        expected10
      )
      (
        actual1,
        actual2,
        actual3,
        actual4,
        actual5,
        actual6,
        actual7,
        actual8,
        actual9,
        actual10
      ) =
      (
        assertTupleElement 1 assert1 expected1 actual1;
        assertTupleElement 2 assert2 expected2 actual2;
        assertTupleElement 3 assert3 expected3 actual3;
        assertTupleElement 4 assert4 expected4 actual4;
        assertTupleElement 5 assert5 expected5 actual5;
        assertTupleElement 6 assert6 expected6 actual6;
        assertTupleElement 7 assert7 expected7 actual7;
        assertTupleElement 8 assert8 expected8 actual8;
        assertTupleElement 9 assert9 expected9 actual9;
        assertTupleElement 10 assert10 expected10 actual10
      )

  end (* local *)

  (****************************************)

  fun assertEqualContainer
      (getLength, getElement, assertElement) expected actual =
      let
        val expectedLength = getLength expected
        val actualLength = getLength actual
        fun scan index =
            if index < actualLength
            then
              (assertElement
               (getElement (expected, index))
               (getElement (actual, index))
               handle
               Fail(GeneralFailure message) =>
               fail ("index " ^ Int.toString index ^ " " ^ message)
             | Fail(NotEqualFailure (expected, actual)) =>
               let val indexString = Int.toString index
               in
                   failByNotEqual
                   (
                     "[...{" ^ indexString ^ "}..., " ^ expected ^ ", ...]",
                     "[...{" ^ indexString ^ "}..., " ^ actual ^ ", ...]"
                   )
               end;
               scan (index + 1))
            else
              ()
      in
        if expectedLength <> actualLength
        then
            failByNotEqual
            (
              Int.toString expectedLength ^ " elements",
              Int.toString actualLength ^ " elements"
            )
        else
          scan 0
      end

  fun assertEqualVector assertElement expected actual =
      assertEqualContainer
      (Vector.length, Vector.sub, assertElement)
      expected
      actual

  val assertEqualWord8Vector =
      assertEqualContainer
      (Word8Vector.length, Word8Vector.sub, assertEqualWord8)

  val assertEqualCharVector =
      assertEqualContainer (CharVector.length, CharVector.sub, assertEqualChar)

  fun assertEqualArray assertElement expected actual =
      assertEqualContainer
      (Array.length, Array.sub, assertElement)
      expected
      actual

  (**
   * asserts that two array references point to the same array.
   *)
  (* This is a generic function used for mono-array also. *)
  fun assertSameArray expected actual =
      (assertEqual
       (fn (expected, actual) => expected = actual)
       (fn array => "array")
       expected
       actual)
      handle Fail(NotEqualFailure (expected, actual)) =>
             failByNotEqual
                 ("array(" ^ expected ^ ")", "array(" ^ actual ^ ")")

  val assertEqualWord8Array =
      assertEqualContainer
      (Word8Array.length, Word8Array.sub, assertEqualWord8)

  val assertSameWord8Array = assertSameArray : Word8Array.array assertEqual

  val assertEqualCharArray =
      assertEqualContainer (CharArray.length, CharArray.sub, assertEqualChar)

  val assertSameCharArray = assertSameArray : CharArray.array assertEqual

  fun assertEqualList assertElement expected actual = 
      assertEqualVector
       assertElement
       (Vector.fromList expected)
       (Vector.fromList actual)

  val assertEqualIntList = assertEqualList assertEqualInt 

  val assertEqualWordList = assertEqualList assertEqualWord

  val assertEqualWord8List = assertEqualList assertEqualWord8

  val assertEqualWord32List = assertEqualList assertEqualWord32

  val assertEqualRealList = assertEqualList assertEqualReal

  val assertEqualCharList = assertEqualList assertEqualChar

  val assertEqualStringList = assertEqualList assertEqualString

  val assertEqualSubstringList = assertEqualList assertEqualSubstring

  (****************************************)

  structure AssertArray =
  struct
    val assertEqualArray = assertEqualArray
    val assertSameArray = assertSameArray
  end

  structure AssertArraySlice =
  struct
  fun assertEqualSlice assertElement =
      assertEqualContainer
          (ArraySlice.length, ArraySlice.sub, assertElement)
  fun assertSameSlice expected actual =
      convertAssertEqual
          ArraySlice.base
          (assertEqual3Tuple (assertSameArray, assertEqualInt, assertEqualInt))
          expected
          actual
  end

  structure AssertBool =
  struct
  val assertEqualBool = assertEqualBool
  end

  structure AssertChar =
  struct
  val assertEqualChar = assertEqualChar
  end

  structure AssertDate =
  struct
  fun weekdayToString Date.Mon = "Mon"
    | weekdayToString Date.Tue = "Tue"
    | weekdayToString Date.Wed = "Wed"
    | weekdayToString Date.Thu = "Thu"
    | weekdayToString Date.Fri = "Fri"
    | weekdayToString Date.Sat = "Sat"
    | weekdayToString Date.Sun = "Sun"

  fun monthToString Date.Jan = "Jan"
    | monthToString Date.Feb = "Feb"
    | monthToString Date.Mar = "Mar"
    | monthToString Date.Apr = "Apr"
    | monthToString Date.May = "May"
    | monthToString Date.Jun = "Jun"
    | monthToString Date.Jul = "Jul"
    | monthToString Date.Aug = "Aug"
    | monthToString Date.Sep = "Sep"
    | monthToString Date.Oct = "Oct"
    | monthToString Date.Nov = "Nov"
    | monthToString Date.Dec = "Dec"

  val assertEqualWeekday =
      assertEqual (fn (x, y) => x = y) weekdayToString

  val assertEqualMonth =
      assertEqual (fn (x, y) => x = y) monthToString

  val assertEqualDate =
      assertEqualByCompare Date.compare Date.toString
  end

  structure AssertGeneral =
  struct
  val assertEqualUnit = assertEqualUnit
  val assertEqualExceptionName = assertEqualExceptionName
(*
  val assertEqualExceptionMessage = assertEqualExceptionMessage
*)
  val assertEqualOrder = assertEqualOrder
  end

  structure AssertIEEEReal =
  struct
  val assertEqualRealOrder =
      assertEqual
          (fn (expected, actual) => expected = actual)
          (fn IEEEReal.LESS => "LESS"
            | IEEEReal.EQUAL => "EQUAL"
            | IEEEReal.GREATER => "GREATER"
            | IEEEReal.UNORDERED => "UNORDERED")

  val assertEqualFloatClass =
      assertEqual
          (fn (x, y) => x = y)
          (fn IEEEReal.INF => "INF"
            | IEEEReal.ZERO => "ZERO"
            | IEEEReal.NORMAL => "NORMAL"
            | IEEEReal.SUBNORMAL => "SUBNORMAL"
            | _ => "NAN") (* NOTE: NAN *)

  val assertEqualRoundingMode =
      assertEqual
          (fn (x, y) => x = y)
          (fn IEEEReal.TO_NEAREST => "TO_NEAREST"
            | IEEEReal.TO_NEGINF => "TO_NEGINF"
            | IEEEReal.TO_POSINF => "TO_POSINF"
            | IEEEReal.TO_ZERO => "TO_ZERO")

  val assertEqualDecimalApprox =
      assertEqual (fn (x, y) => x = y) IEEEReal.toString
  end

  (* for dependency reason, Int is defined later. *)

  structure AssertLargeInt =
  struct
  val assertEqualInt = assertEqual (fn (x, y) => x = y) LargeInt.toString
  end

  structure AssertPosition =
  struct
  val assertEqualInt = assertEqual (fn (x, y) => x = y) Position.toString
  end

  structure AssertList =
  struct
  val assertEqualList = assertEqualList
  end

  structure AssertWord8Array =
  struct
  val assertEqualArray = assertEqualWord8Array
  val assertSameArray = assertSameWord8Array
  end

  structure AssertCharArray =
  struct
  val assertEqualArray = assertEqualCharArray
  val assertSameArray = assertSameCharArray
  end

  structure AssertWord8ArraySlice =
  struct
  val assertEqualSlice =
      assertEqualContainer
          (Word8ArraySlice.length, Word8ArraySlice.sub, assertEqualWord8)
  val assertSameSlice =
      convertAssertEqual
          Word8ArraySlice.base
          (assertEqual3Tuple
               (assertSameWord8Array, assertEqualInt, assertEqualInt))
  end

  structure AssertCharArraySlice =
  struct
  val assertEqualSlice =
      assertEqualContainer
          (CharArraySlice.length, CharArraySlice.sub, assertEqualChar)
  val assertSameSlice =
      convertAssertEqual
          CharArraySlice.base
          (assertEqual3Tuple
               (assertSameCharArray, assertEqualInt, assertEqualInt))
  end

  structure AssertWord8Vector =
  struct
  val assertEqualVector = assertEqualWord8Vector
  end

  structure AssertCharVector =
  struct
  val assertEqualVector = assertEqualCharVector
  end

  structure AssertWord8VectorSlice =
  struct
  val assertEqualSlice =
      assertEqualContainer
          (Word8VectorSlice.length, Word8VectorSlice.sub, assertEqualWord8)
  end

  structure AssertCharVectorSlice =
  struct
  val assertEqualSlice =
      assertEqualContainer
          (CharVectorSlice.length, CharVectorSlice.sub, assertEqualChar)
  end

  structure AssertOption =
  struct
  val assertEqualOption = assertEqualOption
  end

  structure AssertReal =
  struct
  val assertEqualReal = assertEqualReal
  val assertEqualReal_epsilon = assertEqualReal_epsilon
  end

  structure AssertLargeReal =
  struct
  local structure LR = LargeReal
  in
  fun assertEqualReal expected actual =
      case (LR.isNan expected, LR.isNan actual)
       of (true, true) => ()
        | (false, false) =>
          assertEqualByCompare LR.compare LR.toString expected actual
        | _ => failByNotEqual (LR.toString expected, LR.toString actual)
  fun assertEqualReal_epsilon epsilon expected actual =
      case (LR.isNan expected, LR.isNan actual)
       of (true, true) => ()
        | (false, false) =>
          if expected - epsilon <= actual andalso actual <= expected + epsilon
          then ()
          else failByNotEqual (LR.toString expected, LR.toString actual)
        | _ => failByNotEqual (LR.toString expected, LR.toString actual)
  end (* local *)
  end

  structure AssertString =
  struct
  val assertEqualString = assertEqualString
  end
  
  structure AssertStringCvt =
  struct
  val assertEqualRadix =
      assertEqual
          (fn (x, y) => x = y)
          (fn StringCvt.BIN => "BIN"
            | StringCvt.OCT => "OCT"
            | StringCvt.DEC => "DEC"
            | StringCvt.HEX => "HEX")
  val assertEqualRealfmt =
      assertEqual
          (fn (x, y) => x = y)
          (fn StringCvt.SCI NONE => "SCI(NONE)"
            | StringCvt.SCI (SOME n) => "SCI(SOME " ^ Int.toString n ^ ")"
            | StringCvt.FIX NONE => "FIX(NONE)"
            | StringCvt.FIX (SOME n) => "FIX(SOME " ^ Int.toString n ^ ")"
            | StringCvt.GEN NONE => "GEN(NONE)"
            | StringCvt.GEN (SOME n) => "GEN(SOME " ^ Int.toString n ^ ")"
            | StringCvt.EXACT => "EXACT")
  end
  
  structure AssertSubstring =
  struct
  val assertEqualSubstring = assertEqualSubstring
  (* ToDo : assertSameSubstring which compare bases ? *)
  end

  structure AssertTime =
  struct
  val assertEqualTime = assertEqual (fn (x, y) => x = y) Time.toString
  end

  structure AssertVector =
  struct
  val assertEqualVector = assertEqualVector
  end

  structure AssertVectorSlice =
  struct
  fun assertEqualSlice assertElement =
      assertEqualContainer
          (VectorSlice.length, VectorSlice.sub, assertElement)
  end

  structure AssertWord =
  struct
  val assertEqualWord = assertEqualWord
  end

  structure AssertWord8 =
  struct
  val assertEqualWord = assertEqualWord8
  end

  structure AssertLargeWord =
  struct
  val assertEqualWord =
      assertEqual (fn (x, y) => x = y) LargeWord.toString
  end

  structure AssertInt =
  struct
  val assertEqualInt = assertEqualInt
  end

  (***************************************************************************)

end
