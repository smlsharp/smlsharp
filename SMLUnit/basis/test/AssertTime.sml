(**
 * assertions for types defined in Time.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure AssertTime
  : sig

    (****************************************)

    (**
     * Asserts that two Time.time values are equal.
     *)
    val assertEqualTime : Time.time SMLUnit.Assert.assertEqual

    end =
struct

  (****************************************)

  structure A = SMLUnit.Assert

  (****************************************)

  val assertEqualTime =
      A.assertEqual (fn (x, y) => x = y) Time.toString

  (****************************************)

end;