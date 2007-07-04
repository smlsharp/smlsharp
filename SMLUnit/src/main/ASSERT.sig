(**
 * A set of assert functions.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: ASSERT.sig,v 1.5 2007/05/20 05:45:07 kiyoshiy Exp $
 *)
signature ASSERT =
sig

  (***************************************************************************)

  (**
   *  function which asserts the equality of two values.
   * <p>
   *  Functions of this type require two values: expected and actual.
   * They return the actual if the expected and the actual are equal to each
   * other, and raise Fail otherwise.
   * </p>
   *)
  type 'a assertEqual = 'a -> 'a -> 'a

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
   *)
  val assertEqualReal : real assertEqual

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
  val assertTrue : bool -> bool

  (**
   * Asserts that the value is fasle.
   *)
  val assertFalse : bool -> bool

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
  val assertSome : 'a option -> 'a option

  (**
   * Asserts that the option is NONE.
   *)
  val assertNone : 'a option -> 'a option

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

  (****************************************)

  val assertEqualContainer :
      (('a -> int) * (('a * int) -> 'b) * ('b assertEqual)) -> 'a assertEqual

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

  (***************************************************************************)

end
