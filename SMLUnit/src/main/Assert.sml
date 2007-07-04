(**
 * Implementation of assert functions.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: Assert.sml,v 1.4 2007/05/20 05:45:07 kiyoshiy Exp $
 *)
structure Assert :> ASSERT =
struct

  (***************************************************************************)

  type 'a assertEqual = 'a -> 'a -> 'a

  type 'a valueFormatter = 'a -> string

  datatype failure =
           GeneralFailure of string
         | NotEqualFailure of string * string

  (***************************************************************************)

  exception Fail of failure

  (***************************************************************************)

  fun assert message true = ()
    | assert message false = raise (Fail (GeneralFailure message))

  fun fail message = raise (Fail (GeneralFailure message))

  fun failByNotEqual (expected, actual) =
      raise Fail(NotEqualFailure (expected, actual))

  fun assertEqualCompare comparator valueFormatter expected actual =
      if EQUAL = comparator (expected, actual)
      then actual
      else
        let
          val expectedText = valueFormatter expected
          val actualText = valueFormatter actual
        in
          failByNotEqual (expectedText, actualText)
        end

  fun assertEqual comparator valueFormatter expected actual =
      assertEqualCompare
      (fn pair => if comparator pair then EQUAL else LESS)
      valueFormatter
      expected
      actual

  (****************************************)

  (* assertions specialized for every Top-level types *)

  fun assertEqualUnit () () = ()

  fun assertEqualInt expected actual =
      assertEqualCompare Int.compare Int.toString expected actual

  fun assertEqualWord  expected actual = 
      assertEqualCompare Word.compare Word.toString expected actual

  fun assertEqualWord8 expected actual = 
      assertEqualCompare Word8.compare Word8.toString expected actual

  fun assertEqualWord32 expected actual =
      assertEqualCompare Word32.compare Word32.toString expected actual

  fun assertEqualReal expected actual = 
      assertEqualCompare Real.compare Real.toString expected actual

  fun assertEqualChar expected actual = 
      assertEqualCompare Char.compare Char.toString expected actual

  fun assertEqualString expected actual = 
      assertEqualCompare String.compare (fn s => s) expected actual

  fun assertEqualSubstring expected actual = 
      assertEqualCompare Substring.compare Substring.string expected actual

  fun assertEqualExceptionName expected actual =
      (assertEqualCompare
       String.compare
       (fn s => s)
       (exnName expected)
       (exnName actual);
       actual)

(*
  fun assertEqualExceptionMessage expected actual = 
      (assertEqualCompare
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
      if expected = actual then actual
      else (assertReferred (! expected) (! actual); actual)
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
          (NONE, NONE) => actual
        | (NONE, SOME _) => failByNotEqual ("NONE", "SOME(?)")
        | (SOME _, NONE) => failByNotEqual ("SOME(?)", "NONE")
        | (SOME expectedValue, SOME actualValue) =>
          (SOME(assertHolded expectedValue actualValue))
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
      if isSome actual then actual else fail "SOME expected."
  fun assertNone actual =
      if not (isSome actual) then actual else fail "NONE expected."

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

  fun assertEqual2Tuple
      (assertEqual1, assertEqual2)
      (expected1, expected2)
      (actual1, actual2) =
      (
        assertEqual1 expected1 actual1
        handle Fail(NotEqualFailure (expected, actual)) =>
               failByNotEqual ("(" ^ expected ^ ", ?)", "(" ^ actual ^ ", ?)"),
        assertEqual2 expected2 actual2
        handle Fail(NotEqualFailure (expected, actual)) =>
               failByNotEqual ("(?, " ^ expected ^ ")", "(?, " ^ actual ^ ")")
      )

  fun assertEqual3Tuple
      (assertEqual1, assertEqual2, assertEqual3)
      (expected1, expected2, expected3)
      (actual1, actual2, actual3) =
      (
        assertEqual1 expected1 actual1
        handle Fail(NotEqualFailure (expected, actual)) =>
               failByNotEqual
                   ("(" ^ expected ^ ", ?, ?)", "(" ^ actual ^ ", ?, ?)"),
        assertEqual2 expected2 actual2
        handle Fail(NotEqualFailure (expected, actual)) =>
               failByNotEqual
                   ("(?, " ^ expected ^ ", ?)", "(?, " ^ actual ^ ", ?)"),
        assertEqual3 expected3 actual3
        handle Fail(NotEqualFailure (expected, actual)) =>
               failByNotEqual
                   ("(?, ?, " ^ expected ^ ")", "(?, ?, " ^ actual ^ ")")
      )

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
          (scan 0; actual)
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
  fun assertSameArray (expected : 'a array) (actual : 'a array) =
      (assertEqual
       (fn (expected : 'a array, actual) => expected = actual)
       (fn array => "array")
       expected
       actual)
      handle Fail(NotEqualFailure (expected, actual)) =>
             failByNotEqual
                 ("array(" ^ expected ^ ")", "array(" ^ actual ^ ")")

  val assertEqualWord8Array =
      assertEqualContainer
      (Word8Array.length, Word8Array.sub, assertEqualWord8)

  val assertEqualCharArray =
      assertEqualContainer (CharArray.length, CharArray.sub, assertEqualChar)

  fun assertEqualList assertElement expected actual = 
      (assertEqualVector
       assertElement
       (Vector.fromList expected)
       (Vector.fromList actual);
       actual)

  val assertEqualIntList = assertEqualList assertEqualInt 

  val assertEqualWordList = assertEqualList assertEqualWord

  val assertEqualWord8List = assertEqualList assertEqualWord8

  val assertEqualWord32List = assertEqualList assertEqualWord32

  val assertEqualRealList = assertEqualList assertEqualReal

  val assertEqualCharList = assertEqualList assertEqualChar

  val assertEqualStringList = assertEqualList assertEqualString

  val assertEqualSubstringList = assertEqualList assertEqualSubstring

end
