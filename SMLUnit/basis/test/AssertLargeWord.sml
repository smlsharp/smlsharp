(**
 * assertions for types defined in LargeWord
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure AssertLargeWord
  : sig

    (****************************************)

    (**
     * Asserts that two LargeWord.word values are equal.
     *)
    val assertEqualWord : LargeWord.word SMLUnit.Assert.assertEqual

    end =
struct

  (****************************************)

  structure A = SMLUnit.Assert

  (****************************************)

  val assertEqualWord =
      A.assertEqual (fn (x, y) => x = y) LargeWord.toString

  (****************************************)

end;