(**
 * assertions for types defined in IEEEReal.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure AssertIEEEReal
  : sig

  (****************************************)

  (**
   * Asserts that two IEEEReal.real_order values are equal.
   *)
  val assertEqualRealOrder : IEEEReal.real_order SMLUnit.Assert.assertEqual

  (**
   * Asserts that two IEEEReal.float_class values are equal.
   *)
  val assertEqualFloatClass : IEEEReal.float_class SMLUnit.Assert.assertEqual

  (**
   * Asserts that two IEEEReal.rounding_mode values are equal.
   *)
  val assertEqualRoundingMode : IEEEReal.rounding_mode SMLUnit.Assert.assertEqual

  (**
   * Asserts that two IEEEReal.decimal_approx values are equal.
   *)
  val assertEqualDecimalApprox : IEEEReal.decimal_approx SMLUnit.Assert.assertEqual

    end =
struct

  (****************************************)

  structure A = SMLUnit.Assert

  (****************************************)

  fun assertEqualRealOrder expected actual =
      A.assertEqual
          (fn (expected, actual) => expected = actual)
          (fn IEEEReal.LESS => "LESS"
            | IEEEReal.EQUAL => "EQUAL"
            | IEEEReal.GREATER => "GREATER"
            | IEEEReal.UNORDERED => "UNORDERED")
          expected
          actual

  val assertEqualFloatClass =
      A.assertEqual
          (fn (x, y) => x = y)
          (fn IEEEReal.NAN => "NAN"
            | IEEEReal.INF => "INF"
            | IEEEReal.ZERO => "ZERO"
            | IEEEReal.NORMAL => "NORMAL"
            | IEEEReal.SUBNORMAL => "SUBNORMAL")

  val assertEqualRoundingMode =
      A.assertEqual
          (fn (x, y) => x = y)
          (fn IEEEReal.TO_NEAREST => "TO_NEAREST"
            | IEEEReal.TO_NEGINF => "TO_NEGINF"
            | IEEEReal.TO_POSINF => "TO_POSINF"
            | IEEEReal.TO_ZERO => "TO_ZERO")

  val assertEqualDecimalApprox =
      A.assertEqual (fn (x, y) => x = y) IEEEReal.toString

  (****************************************)

end;
