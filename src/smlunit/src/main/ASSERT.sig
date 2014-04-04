(**
 * A set of assert functions.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: ASSERT.sig,v 1.5 2007/05/20 05:45:07 kiyoshiy Exp $
 *)
signature ASSERT =
sig

  (***************************************************************************)

  (**
   *  function which asserts the equality of two values.
   * <p>
   *  Functions of this type require two values: expected and actual.
   * They raise Fail if the expected and the actual are not equal to each
   * other.
   * </p>
   *)
  type 'a assertEqual = 'a -> 'a -> unit

  (**
   *  function which translates a value of the type into human readable
   * text representation.
   *)
  type 'a valueFormatter = 'a -> string

  (**
   * detail of failures of assertions.
   *)
  datatype failure =
           (**
            * @params message
            * @param message description of the failure
            *)
           GeneralFailure of string
           (**
            *  indicates that the expected value and acutal value are not equal
            * to each other.
            * @params (expected, actual)
            * @param expected a string repesentation of expected value
            * @param actual a string representation of actual value
            *)
         | NotEqualFailure of string * string

  (***************************************************************************)

  (**
   * the exception that is raised when any assertion fails.
   * @params failure
   * @param failure detail of the failure
   *)
  exception Fail of failure

  (***************************************************************************)

  (**
   *  general assertion function.
   *
   * @params comparator formatter
   * @param comparator a function which compares two value and returns true if
   *                  they are equal to each other.
   * @param formatter a function which make a string representation of a 
   *                 value of the type
   * @return a function which asserts two values of the type are equal to
   *                 each other.
   *)
  val assertEqual :
      (('a * 'a) -> bool) -> 'a valueFormatter -> 'a assertEqual

  (**
   *  general assertion function.
   * <pre>
   * assertEqualByCompare compare toString
   * </pre>
   * is equivalent to
   * <pre>
   * assertEqual (fn pair => compare pair = EQUAL) toString
   * </pre>
   *
   * @params comparator formatter
   * @param comparator a function which compares two value.
   * @param formatter a function which make a string representation of a 
   *                 value of the type
   * @return a function which asserts two values of the type are equal to
   *                 each other.
   *)
  val assertEqualByCompare :
      (('a * 'a) -> General.order) -> 'a valueFormatter -> 'a assertEqual

  (**
   * @params assert expecteds actual
   * @param assert an assertion function
   * @param expecteds a list of expected values
   * @param actual actual value
   * @return unit if the assert judges that the actual equals to any of
   *      expecteds.
   * @exception Fail raised if none of expecteds equals to the actual.
   *)
  val assertEqualAlternatives : 
      'a assertEqual -> 'a list -> 'a -> unit

  (**
   * asserts that a condition is true.
   * @params message v
   * @param error message
   * @param v if v is false, assertion fails with the specified message.
   *)
  val assert : string -> bool -> unit

  (**
   * always fail with the specified message
   * @params message
   * @param error message
   *)
  val fail : string -> 'a

  (**
   * fail because exepcted value and acutal value are not equal.
   * @params (expected, actual)
   * @param expected a string representation of expected value
   * @param actual a string representation of actual value
   *)
  val failByNotEqual : (string * string) -> 'a

  (**
   * converts an assert function on a type to an assert function on another
   * type.
   * <pre>
   *   convertAssertEqual convert assert expected actual
   * </pre>
   * is equivalent to
   * <pre>
   *   assert (convert expected) (convert actual)
   * </pre>
   * 
   * @params converter assert
   * @param converter a function to convert arguments to the assert.
   * @param assert an assert function on the converted values.
   * @return an assert function 
   *)
  val convertAssertEqual : ('a -> 'b) -> 'b assertEqual -> 'a assertEqual

  (**
   * generates an assert function on a container type.
   * The generated assert function suceeds when both containers are same
   * length, and every pairs of corresponding elements are equal.
   * @params (length, sub, assert)
   * @param length a function which returns the length of a container.
   * @param sub a function which returns the element at the specified position
   *           of a container.
   * @param assert an assert function on the element type.
   *)
  val assertEqualContainer :
      (('a -> int) * (('a * int) -> 'b) * ('b assertEqual)) -> 'a assertEqual

  (****************************************)

  (* assertions specialized for each Top-level types *)

  (**
   * Asserts that two units are equal.
   * This assertion succeeds always.
   *)
  val assertEqualUnit : unit assertEqual

  (**
   * Asserts that two integers are equal.
   *)
  val assertEqualInt : int assertEqual

  (**
   * Asserts that two words are equal.
   *)
  val assertEqualWord : word assertEqual

  (**
   * Asserts that two words are equal.
   *)
  val assertEqualWord8 : Word8.word assertEqual

  (**
   * Asserts that two words are equal.
   *)
  val assertEqualWord32 : Word32.word assertEqual

  (**
   * Asserts that two real numbers are equal.
   * <p>
   * If both expected and actual are Nan, assertion succeeds.
   * Otherwise, if either is Nan, assertion fails.
   * </p>
   *)
  val assertEqualReal : real assertEqual

  (**
   * Asserts that two real numbers are equal within the specified error.
   * <p>
   * If both expected and actual are Nan, assertion succeeds.
   * Otherwise, if either is Nan, assertion fails.
   * </p>
   * <p>
   * If neither is Nan, asserts the condition:
   * <pre>
   * expected - epsilon <= actual <= expected + epsilon
   * </pre>
   * </p>
   * @params epsilon
   * @param epsilon error margin
   *)
  val assertEqualReal_epsilon : real -> real assertEqual

  (**
   * Asserts that two characters are equal.
   *)
  val assertEqualChar : char assertEqual

  (**
   * Asserts that two strings are equal.
   *)
  val assertEqualString : string assertEqual

  (**
   * Asserts that two substrings are equal.
   *)
  val assertEqualSubstring : substring assertEqual

  (**
   * Asserts that two exceptions are equal.
   *)
  val assertEqualExceptionName : exn assertEqual

(*
  val assertEqualExceptionMessage : exn assertEqual
*)

  (****************************************)

  (**
   * asserts that the locations which two references point hold the same value.
   *)
  val assertEqualRef : 'a assertEqual -> 'a ref assertEqual

  (**
   * asserts that two references point to the same location
   *)
  val assertSameRef : 'a ref assertEqual

  (****************************************)

  (**
   * Asserts that two booleans are equal.
   *)
  val assertEqualBool : bool assertEqual

  (**
   * Asserts that the value is true.
   *)
  val assertTrue : bool -> unit

  (**
   * Asserts that the value is fasle.
   *)
  val assertFalse : bool -> unit

  (****************************************)

  (**
   * Asserts that two option values are equal.
   *)
  val assertEqualOption : 'a assertEqual -> 'a option assertEqual

  (**
   * Asserts that two options of integer are equal.
   *)
  val assertEqualIntOption : int option assertEqual

  (**
   * Asserts that two options of word are equal.
   *)
  val assertEqualWordOption : word option assertEqual

  (**
   * Asserts that two options of word are equal.
   *)
  val assertEqualWord8Option : Word8.word option assertEqual

  (**
   * Asserts that two options of word are equal.
   *)
  val assertEqualWord32Option : Word32.word option assertEqual

  (**
   * Asserts that two options of real number are equal.
   *)
  val assertEqualRealOption : real option assertEqual

  (**
   * Asserts that two options of character are equal.
   *)
  val assertEqualCharOption : char option assertEqual

  (**
   * Asserts that two options of string are equal.
   *)
  val assertEqualStringOption : string option assertEqual

  (**
   * Asserts that two options of substring are equal.
   *)
  val assertEqualSubstringOption : substring option assertEqual

  (**
   * Asserts that the option is SOME of any.
   *)
  val assertSome : 'a option -> unit

  (**
   * Asserts that the option is NONE.
   *)
  val assertNone : 'a option -> unit

  (****************************************)

  (**
   * Asserts that two orders are equal.
   *)
  val assertEqualOrder : order assertEqual

  (****************************************)

  (**
   * Asserts that two 2-tuples are equal.
   *)
  val assertEqual2Tuple :
      ('a assertEqual * 'b assertEqual) -> ('a * 'b) assertEqual

  (**
   * Asserts that two 3-tuples are equal.
   *)
  val assertEqual3Tuple :
      ('a assertEqual * 'b assertEqual * 'c assertEqual) ->
      ('a * 'b * 'c) assertEqual

  (**
   * Asserts that two 4-tuples are equal.
   *)
  val assertEqual4Tuple :
      ('a assertEqual * 'b assertEqual * 'c assertEqual * 'd assertEqual) ->
      ('a * 'b * 'c * 'd) assertEqual

  (**
   * Asserts that two 5-tuples are equal.
   *)
  val assertEqual5Tuple :
      (
        'a assertEqual
      * 'b assertEqual
      * 'c assertEqual
      * 'd assertEqual
      * 'e assertEqual
      ) ->
      ('a * 'b * 'c * 'd * 'e) assertEqual

  (**
   * Asserts that two 6-tuples are equal.
   *)
  val assertEqual6Tuple :
      (
        'a assertEqual
      * 'b assertEqual
      * 'c assertEqual
      * 'd assertEqual
      * 'e assertEqual
      * 'f assertEqual
      ) ->
      ('a * 'b * 'c * 'd * 'e * 'f) assertEqual

  (**
   * Asserts that two 7-tuples are equal.
   *)
  val assertEqual7Tuple :
      (
        'a assertEqual
      * 'b assertEqual
      * 'c assertEqual
      * 'd assertEqual
      * 'e assertEqual
      * 'f assertEqual
      * 'g assertEqual
      ) ->
      ('a * 'b * 'c * 'd * 'e * 'f * 'g) assertEqual

  (**
   * Asserts that two 8-tuples are equal.
   *)
  val assertEqual8Tuple :
      (
        'a assertEqual
      * 'b assertEqual
      * 'c assertEqual
      * 'd assertEqual
      * 'e assertEqual
      * 'f assertEqual
      * 'g assertEqual
      * 'h assertEqual
      ) ->
      ('a * 'b * 'c * 'd * 'e * 'f * 'g * 'h) assertEqual

  (**
   * Asserts that two 9-tuples are equal.
   *)
  val assertEqual9Tuple :
      (
        'a assertEqual
      * 'b assertEqual
      * 'c assertEqual
      * 'd assertEqual
      * 'e assertEqual
      * 'f assertEqual
      * 'g assertEqual
      * 'h assertEqual
      * 'i assertEqual
      ) ->
      ('a * 'b * 'c * 'd * 'e * 'f * 'g * 'h * 'i) assertEqual

  (**
   * Asserts that two 10-tuples are equal.
   *)
  val assertEqual10Tuple :
      (
        'a assertEqual
      * 'b assertEqual
      * 'c assertEqual
      * 'd assertEqual
      * 'e assertEqual
      * 'f assertEqual
      * 'g assertEqual
      * 'h assertEqual
      * 'i assertEqual
      * 'j assertEqual
      ) ->
      ('a * 'b * 'c * 'd * 'e * 'f * 'g * 'h * 'i * 'j) assertEqual

  (****************************************)

  (**
   * Asserts that two vectors are equal.
   *)
  val assertEqualVector : ('a assertEqual) -> 'a vector assertEqual

  (**
   * Asserts that two vectors of words are equal.
   *)
  val assertEqualWord8Vector : Word8Vector.vector assertEqual

  (**
   * Asserts that two vectors of characters are equal.
   *)
  val assertEqualCharVector : CharVector.vector assertEqual

  (**
   * Asserts that two arrays are equal.
   *)
  val assertEqualArray : ('a assertEqual) -> 'a array assertEqual

  (**
   * asserts that two array references point to the same array.
   *)
  val assertSameArray : 'a array assertEqual

  (**
   * Asserts that two arrays of words are equal.
   *)
  val assertEqualWord8Array : Word8Array.array assertEqual

  (**
   * Asserts that two arrays of characters are equal.
   *)
  val assertEqualCharArray : CharArray.array assertEqual

  (**
   * Asserts that two lists are equal.
   *)
  val assertEqualList : ('a assertEqual) -> 'a list assertEqual

  (**
   * Asserts that two lists of integers are equal.
   *)
  val assertEqualIntList : int list assertEqual

  (**
   * Asserts that two lists of words are equal.
   *)
  val assertEqualWordList : word list assertEqual

  (**
   * Asserts that two lists of words are equal.
   *)
  val assertEqualWord8List : Word8.word list assertEqual

  (**
   * Asserts that two lists of words are equal.
   *)
  val assertEqualWord32List : Word32.word list assertEqual

  (**
   * Asserts that two lists of reals are equal.
   *)
  val assertEqualRealList : real list assertEqual

  (**
   * Asserts that two lists of characters are equal.
   *)
  val assertEqualCharList : char list assertEqual

  (**
   * Asserts that two lists of strings are equal.
   *)
  val assertEqualStringList : string list assertEqual

  (**
   * Asserts that two lists of substrings are equal.
   *)
  val assertEqualSubstringList : substring list assertEqual

  (********************)

  (**
   * assert functions for Array.
   *)
  structure AssertArray :
  sig
    (**
     * Asserts that the contents of two Array.array are equal.
     *)
    val assertEqualArray : 'a assertEqual -> 'a Array.array assertEqual
    (**
     * Asserts that two arguments are the same Array.array.
     *)
    val assertSameArray : 'a Array.array assertEqual
  end

  (**
   * assert functions for ArraySlice.
   *)
  structure AssertArraySlice :
  sig
    (**
     * Asserts that the contents of two ArraySlice.slice are equal.
     *)
    val assertEqualSlice : 'a assertEqual -> 'a ArraySlice.slice assertEqual
    (**
     * Asserts that two ArraySlice.slice have the same base.
     *)
    val assertSameSlice : 'a ArraySlice.slice assertEqual
  end

  (**
   * assert functions for Bool.
   *)
  structure AssertBool :
  sig
    (**
     * Asserts that two Bool.bool values are equal.
     *)
    val assertEqualBool : Bool.bool assertEqual
  end

  (**
   * assert functions for Char.
   *)
  structure AssertChar :
  sig
    (**
     * Asserts that two Char.char values are equal.
     *)
    val assertEqualChar : Char.char assertEqual
  end

  (**
   * assert functions for Date.
   *)
  structure AssertDate :
  sig
    (**
     * Asserts that two Date.weekday values are equal.
     *)
    val assertEqualWeekday : Date.weekday assertEqual

    (**
     * Asserts that two Date.month values are equal.
     *)
    val assertEqualMonth : Date.month assertEqual

    (**
     * Asserts that two Date.date values are equal.
     *)
    val assertEqualDate : Date.date assertEqual
  end

  (**
   * assert functions for General.
   *)
  structure AssertGeneral :
  sig
    (**
     * Asserts that two General.unit values are equal.
     *)
    val assertEqualUnit : General.unit assertEqual
    (**
     * Asserts that names of two General.exn values are equal.
     *)
    val assertEqualExceptionName : General.exn assertEqual
(*
    val assertEqualExceptionMessage : General.exn assertEqual
*)
    (**
     * Asserts that two General.order values are equal.
     *)
    val assertEqualOrder : General.order assertEqual
  end

  (**
   * assert functions for IEEEReal.
   *)
  structure AssertIEEEReal :
  sig
    (**
     * Asserts that two IEEEReal.real_order values are equal.
     *)
    val assertEqualRealOrder : IEEEReal.real_order assertEqual

    (**
     * Asserts that two IEEEReal.float_class values are equal.
     *)
    val assertEqualFloatClass : IEEEReal.float_class assertEqual

    (**
     * Asserts that two IEEEReal.rounding_mode values are equal.
     *)
    val assertEqualRoundingMode : IEEEReal.rounding_mode assertEqual

    (**
     * Asserts that two IEEEReal.decimal_approx values are equal.
     *)
    val assertEqualDecimalApprox : IEEEReal.decimal_approx assertEqual

  end

  (**
   * assert functions for Int.
   *)
  structure AssertInt :
  sig
    (**
     * Asserts that two Int.int values are equal.
     *)
    val assertEqualInt : Int.int assertEqual
  end

  (**
   * assert functions for LargeInt.
   *)
  structure AssertLargeInt :
  sig
    (**
     * Asserts that two LargeInt.int values are equal.
     *)
    val assertEqualInt : LargeInt.int assertEqual
  end

  (**
   * assert functions for Position.
   *)
  structure AssertPosition :
  sig
    (**
     * Asserts that two Position.int values are equal.
     *)
    val assertEqualInt : Position.int assertEqual
  end

  (**
   * assert functions for List.
   *)
  structure AssertList :
  sig
    (**
     * Asserts that two List.list values are equal.
     *)
    val assertEqualList : 'a assertEqual -> 'a List.list assertEqual
  end

  (**
   * assert functions for Word8Array.
   *)
  structure AssertWord8Array :
  sig
    (**
     * Asserts that the contents of two Word8Array.array are equal.
     *)
    val assertEqualArray : Word8Array.array assertEqual
    (**
     * Asserts that two arguments are the same Word8Array.array.
     *)
    val assertSameArray : Word8Array.array assertEqual
  end

  (**
   * assert functions for CharArray.
   *)
  structure AssertCharArray :
  sig
    (**
     * Asserts that the contents of two CharArray.array are equal.
     *)
    val assertEqualArray : CharArray.array assertEqual
    (**
     * Asserts that two arguments are the same CharArray.array.
     *)
    val assertSameArray : CharArray.array assertEqual
  end

  (**
   * assert functions for Word8ArraySlice.
   *)
  structure AssertWord8ArraySlice :
  sig
    (**
     * Asserts that the contents of two Word8ArraySlice.slice are equal.
     *)
    val assertEqualSlice : Word8ArraySlice.slice assertEqual
    (**
     * Asserts that two Word8ArraySlice.slice have the same base.
     *)
    val assertSameSlice : Word8ArraySlice.slice assertEqual
  end

  (**
   * assert functions for CharArraySlice.
   *)
  structure AssertCharArraySlice :
  sig
    (**
     * Asserts that the contents of two CharArraySlice.slice are equal.
     *)
    val assertEqualSlice : CharArraySlice.slice assertEqual
    (**
     * Asserts that two CharArraySlice.slice have the same base.
     *)
    val assertSameSlice : CharArraySlice.slice assertEqual
  end

  (**
   * assert functions for Word8Vector.
   *)
  structure AssertWord8Vector :
  sig
    (**
     * Asserts that the contents of two Word8Vector.vector values are equal.
     *)
    val assertEqualVector : Word8Vector.vector assertEqual
  end

  (**
   * assert functions for CharVector.
   *)
  structure AssertCharVector :
  sig
    (**
     * Asserts that the contents of two CharVector.vector values are equal.
     *)
    val assertEqualVector : CharVector.vector assertEqual
  end

  (**
   * assert functions for Word8VectorSlice.
   *)
  structure AssertWord8VectorSlice :
  sig
    (**
     * Asserts that the contents of two Word8VectorSlice.slice values are
     * equal.
     *)
    val assertEqualSlice : Word8VectorSlice.slice assertEqual
  end

  (**
   * assert functions for CharVectorSlice.
   *)
  structure AssertCharVectorSlice :
  sig
    (**
     * Asserts that the contents of two CharVectorSlice.slice values are equal.
     *)
    val assertEqualSlice : CharVectorSlice.slice assertEqual
  end

  (**
   * assert functions for Option.
   *)
  structure AssertOption :
  sig
    (**
     * Asserts that two Option.option values are equal.
     *)
    val assertEqualOption : 'a assertEqual -> 'a Option.option assertEqual
  end

  (**
   * assert functions for Real.
   *)
  structure AssertReal :
  sig
    (**
     * Asserts that two Real.real values are equal.
     *)
    val assertEqualReal : Real.real assertEqual
    (**
     * Asserts that two Real.real values are equal within the specified error.
     *)
    val assertEqualReal_epsilon : Real.real -> Real.real assertEqual
  end

  (**
   * assert functions for LargeReal.
   *)
  structure AssertLargeReal :
  sig
    (**
     * Asserts that two LargeReal.real values are equal.
     *)
    val assertEqualReal : LargeReal.real assertEqual
    (**
     * Asserts that two LargeReal.real values are equal within the specified
     * error.
     *)
    val assertEqualReal_epsilon : LargeReal.real -> LargeReal.real assertEqual
  end

  (**
   * assert functions for String.
   *)
  structure AssertString :
  sig
    (**
     * Asserts that two String.string values are equal.
     *)
    val assertEqualString : String.string assertEqual
  end

  (**
   * assert functions for StringCvt.
   *)
  structure AssertStringCvt :
  sig
    (**
     * Asserts that two StringCvt.radix are equal.
     *)
    val assertEqualRadix : StringCvt.radix assertEqual
    (**
     * Asserts that two StringCvt.realfmt are equal.
     *)
    val assertEqualRealfmt : StringCvt.realfmt assertEqual
  end

  (**
   * assert functions for Substring.
   *)
  structure AssertSubstring :
  sig
    (**
     * Asserts that the contents of two Substring.substring values are equal.
     *)
    val assertEqualSubstring : Substring.substring assertEqual
  end

  (**
   * assert functions for Time.
   *)
  structure AssertTime :
  sig
    (**
     * Asserts that two Time.time values are equal.
     *)
    val assertEqualTime : Time.time assertEqual
  end

  (**
   * assert functions for Vector.
   *)
  structure AssertVector :
  sig
    (**
     * Asserts that the contents of two Vector.vector values are equal.
     *)
    val assertEqualVector : 'a assertEqual -> 'a Vector.vector assertEqual
  end

  (**
   * assert functions for VectorSlice.
   *)
  structure AssertVectorSlice :
  sig
    (**
     * Asserts that the contents of two VectorSlice.slice values are equal.
     *)
    val assertEqualSlice : 'a assertEqual -> 'a VectorSlice.slice assertEqual
  end

  (**
   * assert functions for Word.
   *)
  structure AssertWord :
  sig
    (**
     * Asserts that two Word.word values are equal.
     *)
    val assertEqualWord : Word.word assertEqual
  end

  (**
   * assert functions for Word8.
   *)
  structure AssertWord8 :
  sig
    (**
     * Asserts that two Word8.word values are equal.
     *)
    val assertEqualWord : Word8.word assertEqual
  end

  (**
   * assert functions for LargeWord.
   *)
  structure AssertLargeWord :
  sig
    (**
     * Asserts that two LargeWord.word values are equal.
     *)
    val assertEqualWord : LargeWord.word assertEqual
  end

  (***************************************************************************)

end
