(**
 * assertions for types defined in LargeReal.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure AssertLargeReal
  : sig

    (****************************************)

    (**
     * Asserts that two LargeReal.real values are equal.
     *)
    val assertEqualReal : LargeReal.real SMLUnit.Assert.assertEqual

    end =
struct

  (****************************************)

  structure A = SMLUnit.Assert
  structure LR = LargeReal

  (****************************************)

  fun assertEqualReal expected actual =
      case (LR.isNan expected, LR.isNan actual)
       of (true, true) => actual
        | (false, false) =>
          A.assertEqualByCompare LR.compare LR.toString expected actual
        | _ => A.failByNotEqual (LR.toString expected, LR.toString actual)

  (****************************************)

end;