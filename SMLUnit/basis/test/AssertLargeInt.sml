(**
 * assertions for types defined in LargeInt.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure AssertLargeInt
  : sig

    (****************************************)

    (**
     * Asserts that two LargeInt.int values are equal.
     *)
    val assertEqualInt : LargeInt.int SMLUnit.Assert.assertEqual

    end =
struct

  (****************************************)

  structure A = SMLUnit.Assert

  (****************************************)

  val assertEqualInt =
      A.assertEqual (fn (x, y) => x = y) LargeInt.toString

  (****************************************)

end;