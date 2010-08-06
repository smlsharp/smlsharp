(**
 * test cases for Real structure.
 *
 * <p>
 * Real values are classified to 8 classes.
 * <ul>
 *   <li>positive normal</li>
 *   <li>negative normal</li>
 *   <li>positive zero</li>
 *   <li>negative zero</li>
 *   <li>positive infinity</li>
 *   <li>negative infinity</li>
 *   <li>positive nan</li>
 *   <li>negative nan</li>
 * </ul>
 * Real functions should be tested for each class.
 * If it takes n-reals, 8^n cases should be tested...
 * </p>
 * (Strictly, there are more two classes: positive subnormal and negative
 * subnormal.)
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure Real001 =
struct

  (************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test
  structure AI = SMLUnit.Assert.AssertIEEEReal
  structure ALI = SMLUnit.Assert.AssertLargeInt
  structure ALR = SMLUnit.Assert.AssertLargeReal
  open A
  open AI

  structure R = Real
  structure IR = IEEEReal
  structure LR = LargeReal
  structure I = Int
  structure LI = LargeInt

  (************************************************************)

  type manExp = {man : real, exp : int}
  type wholeFrac = {whole : real, frac : real}

  (************************************************************)

  val epsilon = 0.0001
  val assertEqualReal = assertEqualReal_epsilon epsilon
  val assertEqualRealOption = assertEqualOption assertEqualReal
  val assertEqualRealList = assertEqualList assertEqualReal

  val assertEqualRSOption =
      assertEqualOption
          (assertEqual2Tuple (assertEqualReal, assertEqualString))

  val assertEqual4Bool =
      assertEqual4Tuple
          (assertEqualBool, assertEqualBool, assertEqualBool, assertEqualBool)

  val assertEqual4Int =
      assertEqual4Tuple
          (assertEqualInt, assertEqualInt, assertEqualInt, assertEqualInt)

  val assertEqual4LargeInt =
      assertEqual4Tuple
          (
            ALI.assertEqualInt,
            ALI.assertEqualInt,
            ALI.assertEqualInt,
            ALI.assertEqualInt
          )

  val assertEqual4Real =
      assertEqual4Tuple
          (assertEqualReal, assertEqualReal, assertEqualReal, assertEqualReal)

  val assertEqual5Real =
      assertEqual5Tuple
          (
            assertEqualReal,
            assertEqualReal,
            assertEqualReal,
            assertEqualReal,
            assertEqualReal
          )

  fun assertEqualManExp (expected : manExp) (actual : manExp) =
      assertEqual2Tuple
          (assertEqualReal, assertEqualInt)
          (#man expected, #exp expected)
          (#man actual, #exp actual)

  fun assertEqualWholeFrac (expected : wholeFrac) (actual : wholeFrac) =
      assertEqual2Tuple
          (assertEqualReal, assertEqualReal)
          (#whole expected, #frac expected)
          (#whole actual, #frac actual)

  val posInf = R.posInf
  val negInf = R.negInf

  val posNan = R.copySign(posInf * 0.0, 1.0)
  val negNan = R.copySign(negInf * 0.0, ~1.0)

  val pos0 = 0.0
  val neg0 = ~0.0

  val I2i = LI.toInt

  val (maxInt_r, maxInt) =
      case I.precision
       of SOME 31 => (1073741823.0, valOf I.maxInt)
        | SOME 32 => (2147483647.0, valOf I.maxInt)
        | SOME 64 => (9223372036854775807.0, valOf I.maxInt)
        | NONE => (9223372036854775807.0, I2i 9223372036854775807) (* ? *)
  val (minInt_r, minInt) =
      case I.precision
       of SOME 31 => (~1073741824.0, valOf I.minInt)
        | SOME 32 => (~2147483648.0, valOf I.minInt)
        | SOME 64 => (~9223372036854775808.0, valOf I.minInt)
        | NONE => (~9223372036854775808.0, I2i ~9223372036854775808) (* ? *)
  val maxInt_L = LargeInt.fromInt maxInt
  val minInt_L = LargeInt.fromInt minInt

  (**********)

  local
    fun test args expected =
        assertEqual5Real
            expected (R.+ args, R.- args, R.* args, R./ args, R.rem args)
  in
  fun binArith_pos () =
      let
        val binArith_p_p = test (1.23, 2.46) (3.69, ~1.23, 3.0258, 0.5, 1.23)
        val binArith_p_n = test (1.23, ~2.46) (~1.23, 3.69, ~3.0258, ~0.5, 1.23)
        val binArith_p_p0 = test (1.23, pos0) (1.23, 1.23, pos0, posInf, posNan)
        val binArith_p_n0 = test (1.23, neg0) (1.23, 1.23, neg0, negInf, negNan)
        val binArith_p_pinf = test (1.23, posInf) (posInf, negInf, posInf, pos0, 1.23)
        val binArith_p_ninf = test (1.23, negInf) (negInf, posInf, negInf, neg0, 1.23)
        val binArith_p_pnan = test (1.23, posNan) (posNan, posNan, posNan, posNan, posNan)
        val binArith_p_nnan = test (1.23, negNan) (negNan, negNan, negNan, negNan, negNan)
      in () end
  fun binArith_neg () =
      let
        val binArith_n_p = test (~1.23, 2.46) (1.23, ~3.69, ~3.0258, ~0.5, ~1.23)
        val binArith_n_n = test (~1.23, ~2.46) (~3.69, 1.23, 3.0258, 0.5, ~1.23)
        val binArith_n_p0 = test (~1.23, pos0) (~1.23, ~1.23, neg0, negInf, negNan)
        val binArith_n_n0 = test (~1.23, neg0) (~1.23, ~1.23, pos0, posInf, posNan)
        val binArith_n_pinf = test (~1.23, posInf) (posInf, negInf, negInf, neg0, ~1.23)
        val binArith_n_ninf = test (~1.23, negInf) (negInf, posInf, posInf, pos0, ~1.23)
        val binArith_n_pnan = test (~1.23, posNan) (posNan, posNan, posNan, posNan, posNan)
        val binArith_n_nnan = test (~1.23, negNan) (negNan, negNan, negNan, negNan, negNan)
      in () end
  fun binArith_p0 () =
      let
        val binArith_p0_p = test (pos0, 2.46) (2.46, ~2.46, pos0, pos0, pos0)
        val binArith_p0_n = test (pos0, ~2.46) (~2.46, 2.46, neg0, neg0, pos0)
        val binArith_p0_p0 = test (pos0, pos0) (pos0, pos0, pos0, posNan, posNan)
        val binArith_p0_n0 = test (pos0, neg0) (pos0, pos0, neg0, negNan, negNan)
        val binArith_p0_pinf = test (pos0, posInf) (posInf, negInf, posNan, pos0, pos0)
        val binArith_p0_ninf = test (pos0, negInf) (negInf, posInf, negNan, neg0, pos0)
        val binArith_p0_pnan = test (pos0, posNan) (posNan, posNan, posNan, posNan, posNan)
        val binArith_p0_nnan = test (pos0, negNan) (negNan, negNan, negNan, negNan, negNan)
      in () end
  fun binArith_n0 () =
      let
        val binArith_n0_p = test (neg0, 2.46) (2.46, ~2.46, pos0, pos0, pos0)
        val binArith_n0_n = test (neg0, ~2.46) (~2.46, 2.46, neg0, neg0, pos0)
        val binArith_n0_p0 = test (neg0, pos0) (neg0, neg0, neg0, negNan, negNan)
        val binArith_n0_n0 = test (neg0, neg0) (neg0, neg0, pos0, posNan, negNan)
        val binArith_n0_pinf = test (neg0, posInf) (posInf, negInf, negNan, neg0, neg0)
        val binArith_n0_ninf = test (neg0, negInf) (negInf, posInf, posNan, pos0, neg0)
        val binArith_n0_pnan = test (neg0, posNan) (posNan, posNan, posNan, posNan, posNan)
        val binArith_n0_nnan = test (neg0, negNan) (negNan, negNan, negNan, negNan, negNan)
      in () end
  fun binArith_pinf () =
      let
        val binArith_pinf_p = test (posInf, 2.46) (posInf, posInf, posInf, posInf, posNan)
        val binArith_pinf_n = test (posInf, ~2.46) (posInf, posInf, negInf, negInf, posNan)
        val binArith_pinf_p0 = test (posInf, pos0) (posInf, posInf, posNan, posInf, posNan)
        val binArith_pinf_n0 = test (posInf, neg0) (posInf, posInf, negNan, negInf, negNan)
        val binArith_pinf_pinf = test (posInf, posInf) (posInf, posNan, posInf, posNan, posNan)
        val binArith_pinf_ninf = test (posInf, negInf) (posNan, posInf, negInf, negNan, posNan)
        val binArith_pinf_pnan = test (posInf, posNan) (posNan, posNan, posNan, posNan, posNan)
        val binArith_pinf_nnan = test (posInf, negNan) (negNan, negNan, negNan, negNan, negNan)
      in () end
  fun binArith_ninf () =
      let
        val binArith_ninf_p = test (negInf, 2.46) (negInf, negInf, negInf, negInf, negNan)
        val binArith_ninf_n = test (negInf, ~2.46) (negInf, negInf, posInf, posInf, negNan)
        val binArith_ninf_p0 = test (negInf, pos0) (negInf, negInf, negNan, negInf, negNan)
        val binArith_ninf_n0 = test (negInf, neg0) (negInf, negInf, posNan, posInf, posNan)
        val binArith_ninf_pinf = test (negInf, posInf) (negNan, negInf, negInf, negNan, negNan)
        val binArith_ninf_ninf = test (negInf, negInf) (negInf, negNan, posInf, posNan, posNan)
        val binArith_ninf_pnan = test (negInf, posNan) (posNan, posNan, posNan, posNan, posNan)
        val binArith_ninf_nnan = test (negInf, negNan) (negNan, negNan, negNan, negNan, negNan)
      in () end
  fun binArith_pnan () =
      let
        val binArith_pnan_p = test (posNan, 2.46) (posNan, posNan, posNan, posNan, posNan)
        val binArith_pnan_n = test (posNan, ~2.46) (posNan, posNan, posNan, posNan, posNan)
        val binArith_pnan_p0 = test (posNan, pos0) (posNan, posNan, posNan, posNan, posNan)
        val binArith_pnan_n0 = test (posNan, neg0) (posNan, posNan, posNan, posNan, posNan)
        val binArith_pnan_pinf = test (posNan, posInf) (posNan, posNan, posNan, posNan, posNan)
        val binArith_pnan_ninf = test (posNan, negInf) (posNan, posNan, posNan, posNan, posNan)
        val binArith_pnan_pnan = test (posNan, posNan) (posNan, posNan, posNan, posNan, posNan)
        val binArith_pnan_nnan = test (posNan, negNan) (posNan, posNan, posNan, posNan, posNan)
      in () end
  fun binArith_nnan () =
      let
        val binArith_nnan_p = test (negNan, 2.46) (posNan, posNan, posNan, posNan, posNan)
        val binArith_nnan_n = test (negNan, ~2.46) (posNan, posNan, posNan, posNan, posNan)
        val binArith_nnan_p0 = test (negNan, pos0) (posNan, posNan, posNan, posNan, posNan)
        val binArith_nnan_n0 = test (negNan, neg0) (posNan, posNan, posNan, posNan, posNan)
        val binArith_nnan_pinf = test (negNan, posInf) (posNan, posNan, posNan, posNan, posNan)
        val binArith_nnan_ninf = test (negNan, negInf) (posNan, posNan, posNan, posNan, posNan)
        val binArith_nnan_pnan = test (negNan, posNan) (posNan, posNan, posNan, posNan, posNan)
        val binArith_nnan_nnan = test (negNan, negNan) (posNan, posNan, posNan, posNan, posNan)
      in () end
  end (* local *)

  (**********)

  (* Each argument of trinary-arithmetic operators can be any of 8 types.
   * There are 8^3=512 combinations of 3 argument types.
   * It is impossible to cover all of them.
   *)
  fun triArith0001 () =
      let
        (* multiply-addition *)
        val triArith_p_p_p_ma = R.*+(1.23, 2.46, 3.69)
        val _ = assertEqualReal (1.23 * 2.46 + 3.69) triArith_p_p_p_ma

        (* multiply-subtract *)
        val triArith_p_p_p_ms = R.*-(1.23, 2.46, 3.69)
        val _ = assertEqualReal (1.23 * 2.46 - 3.69) triArith_p_p_p_ms
      in () end

  (**********)

  local fun test arg expected = assertEqualReal expected (R.~ arg)
  in
  fun negation0001 () =
      let
        val negation_p = test 1.23 ~1.23
        val negation_n = test ~1.23 1.23
        val negation_p0 = test pos0 neg0
        val negation_n0 = test neg0 pos0
        val negation_pinf = test posInf negInf
        val negation_ninf = test negInf posInf
        val negation_pnan = test posNan negNan
        val negation_nnan = test negNan posNan
      in () end
  end (* local *)

  (**********)

  local fun test arg expected = assertEqualReal expected (R.abs arg)
  in
  fun abs_normal () =
      let
        val abs_p = test 1.23 1.23
        val abs_m = test ~1.23 1.23
      in () end
  fun abs_zero () =
      let
        val abs_p0 = test pos0 pos0
        val abs_n0 = test neg0 pos0
      in () end
  fun abs_inf () =
      let
        val abs_pinf = test posInf posInf
        val abs_ninf = test negInf posInf
      in () end
  fun abs_nan () =
      let
        val abs_pnan = test posNan posNan
        val abs_nnan = test negNan posNan
      in () end
  end (* local *)

  (**********)

  local fun test arg expected = assertEqualReal expected (R.min arg)
  in
  fun min_pos () =
      let
        val min_p_p_l = test (1.23, 2.34) 1.23
        val min_p_p_g = test (2.34, 1.23) 1.23
        val min_p_n = test (1.23, ~2.34) ~2.34
        val min_p_p0 = test (1.23, pos0) pos0
        val min_p_n0 = test (1.23, neg0) neg0
        val min_p_pinf = test (1.23, posInf) 1.23
        val min_p_ninf = test (1.23, negInf) negInf
        val min_p_pnan = test (1.23, posNan) 1.23
        val min_p_nnan = test (1.23, negNan) 1.23
      in () end
  fun min_neg () =
      let
        val min_n_n_l = test (~2.34, ~1.23) ~2.34
        val min_n_n_g = test (~1.23, ~2.34) ~2.34
        val min_n_p = test (~2.34, 1.23) ~2.34
        val min_n_p0 = test (~1.23, pos0) ~1.23
        val min_n_n0 = test (~1.23, neg0) ~1.23
        val min_n_pinf = test (~1.23, posInf) ~1.23
        val min_n_ninf = test (~1.23, negInf) negInf
        val min_n_pnan = test (~1.23, posNan) ~1.23
        val min_n_nnan = test (~1.23, negNan) ~1.23
      in () end
  fun min_p0 () =
      let
        val min_p0_p = test (pos0, 1.23) pos0
        val min_p0_n = test (pos0, ~1.23) ~1.23
        val min_p0_p0 = test (pos0, pos0) pos0
        val min_p0_n0 = test (pos0, neg0) neg0
        val min_p0_pinf = test (pos0, posInf) pos0
        val min_p0_ninf = test (pos0, negInf) negInf
        val min_p0_pnan = test (pos0, posNan) pos0
        val min_p0_nnan = test (pos0, negNan) pos0
      in () end
  fun min_n0 () =
      let
        val min_n0_p = test (neg0, 1.23) neg0
        val min_n0_n = test (neg0, ~1.23) ~1.23
        val min_n0_p0 = test (neg0, pos0) neg0
        val min_n0_n0 = test (neg0, neg0) neg0
        val min_n0_pinf = test (neg0, posInf) neg0
        val min_n0_ninf = test (neg0, negInf) negInf
        val min_n0_pnan = test (neg0, posNan) neg0
        val min_n0_nnan = test (neg0, negNan) neg0
      in () end
  fun min_pinf () =
      let
        val min_pinf_p = test (posInf, 1.23) 1.23
        val min_pinf_n = test (posInf, ~1.23) ~1.23
        val min_pinf_p0 = test (posInf, pos0) pos0
        val min_pinf_n0 = test (posInf, neg0) neg0
        val min_pinf_pinf = test (posInf, posInf) posInf
        val min_pinf_ninf = test (posInf, negInf) negInf 
        val min_pinf_pnan = test (posInf, posNan) posInf
        val min_pinf_nnan = test (posInf, negNan) posInf
      in () end
  fun min_ninf () =
      let
        val min_ninf_p = test (negInf, 1.23) negInf
        val min_ninf_n = test (negInf, ~1.23) negInf
        val min_ninf_p0 = test (negInf, pos0) negInf
        val min_ninf_n0 = test (negInf, neg0) negInf
        val min_ninf_pinf = test (negInf, posInf) negInf
        val min_ninf_ninf = test (negInf, negInf) negInf 
        val min_ninf_pnan = test (negInf, posNan) negInf
        val min_ninf_nnan = test (negInf, negNan) negInf
      in () end
  fun min_pnan () =
      let
        val min_pnan_p = test (posNan, 1.23) 1.23
        val min_pnan_n = test (posNan, ~1.23) ~1.23
        val min_pnan_p0 = test (posNan, pos0) pos0
        val min_pnan_n0 = test (posNan, neg0) neg0
        val min_pnan_pinf = test (posNan, posInf) posInf
        val min_pnan_ninf = test (posNan, negInf) negInf 
        val min_pnan_pnan = test (posNan, posNan) posNan
        val min_pnan_nnan = test (posNan, negNan) posNan
      in () end
  fun min_nnan () =
      let
        val min_nnan_p = test (negNan, 1.23) 1.23
        val min_nnan_n = test (negNan, ~1.23) ~1.23
        val min_nnan_p0 = test (negNan, pos0) pos0
        val min_nnan_n0 = test (negNan, neg0) neg0
        val min_nnan_pinf = test (negNan, posInf) posInf
        val min_nnan_ninf = test (negNan, negInf) negInf 
        val min_nnan_pnan = test (negNan, posNan) negNan
        val min_nnan_nnan = test (negNan, negNan) negNan
      in () end

  end (* local min *)

  (**********)

  local fun test arg expected = assertEqualReal expected (R.max arg)
  in
  fun max_pos () =
      let
        val max_p_p_l = test (1.23, 2.34) 2.34
        val max_p_p_g = test (2.34, 1.23) 2.34
        val max_p_n = test (1.23, ~2.34) 1.23
        val max_p_p0 = test (1.23, pos0) 1.23
        val max_p_n0 = test (1.23, neg0) 1.23
        val max_p_pinf = test (1.23, posInf) posInf
        val max_p_ninf = test (1.23, negInf) 1.23
        val max_p_pnan = test (1.23, posNan) 1.23
        val max_p_nnan = test (1.23, negNan) 1.23
      in () end
  fun max_neg () =
      let
        val max_n_n_l = test (~2.34, ~1.23) ~1.23
        val max_n_n_g = test (~1.23, ~2.34) ~1.23
        val max_n_p = test (~2.34, 1.23) 1.23
        val max_n_p0 = test (~1.23, pos0) pos0
        val max_n_n0 = test (~1.23, neg0) neg0
        val max_n_pinf = test (~1.23, posInf) posInf
        val max_n_ninf = test (~1.23, negInf) ~1.23
        val max_n_pnan = test (~1.23, posNan) ~1.23
        val max_n_nnan = test (~1.23, negNan) ~1.23
      in () end
  fun max_p0 () =
      let
        val max_p0_p = test (pos0, 1.23) 1.23
        val max_p0_n = test (pos0, ~1.23) pos0
        val max_p0_p0 = test (pos0, pos0) pos0
        val max_p0_n0 = test (pos0, neg0) pos0
        val max_p0_pinf = test (pos0, posInf) posInf
        val max_p0_ninf = test (pos0, negInf) pos0
        val max_p0_pnan = test (pos0, posNan) pos0
        val max_p0_nnan = test (pos0, negNan) pos0
      in () end
  fun max_n0 () =
      let
        val max_n0_p = test (neg0, 1.23) 1.23
        val max_n0_n = test (neg0, ~1.23) neg0
        val max_n0_p0 = test (neg0, pos0) pos0
        val max_n0_n0 = test (neg0, neg0) neg0
        val max_n0_pinf = test (neg0, posInf) posInf
        val max_n0_ninf = test (neg0, negInf) neg0
        val max_n0_pnan = test (neg0, posNan) neg0
        val max_n0_nnan = test (neg0, negNan) neg0
      in () end
  fun max_pinf () =
      let
        val max_pinf_p = test (posInf, 1.23) posInf
        val max_pinf_n = test (posInf, ~1.23) posInf
        val max_pinf_p0 = test (posInf, pos0) posInf
        val max_pinf_n0 = test (posInf, neg0) posInf
        val max_pinf_pinf = test (posInf, posInf) posInf
        val max_pinf_ninf = test (posInf, negInf) posInf 
        val max_pinf_pnan = test (posInf, posNan) posInf
        val max_pinf_nnan = test (posInf, negNan) posInf
      in () end
  fun max_ninf () =
      let
        val max_ninf_p = test (negInf, 1.23) 1.23
        val max_ninf_n = test (negInf, ~1.23) ~1.23
        val max_ninf_p0 = test (negInf, pos0) pos0
        val max_ninf_n0 = test (negInf, neg0) neg0
        val max_ninf_pinf = test (negInf, posInf) posInf
        val max_ninf_ninf = test (negInf, negInf) negInf 
        val max_ninf_pnan = test (negInf, posNan) negInf
        val max_ninf_nnan = test (negInf, negNan) negInf
      in () end
  fun max_pnan () =
      let
        val max_pnan_p = test (posNan, 1.23) 1.23
        val max_pnan_n = test (posNan, ~1.23) ~1.23
        val max_pnan_p0 = test (posNan, pos0) pos0
        val max_pnan_n0 = test (posNan, neg0) neg0
        val max_pnan_pinf = test (posNan, posInf) posInf
        val max_pnan_ninf = test (posNan, negInf) negInf 
        val max_pnan_pnan = test (posNan, posNan) posNan
        val max_pnan_nnan = test (posNan, negNan) posNan
      in () end
  fun max_nnan () =
      let
        val max_nnan_p = test (negNan, 1.23) 1.23
        val max_nnan_n = test (negNan, ~1.23) ~1.23
        val max_nnan_p0 = test (negNan, pos0) pos0
        val max_nnan_n0 = test (negNan, neg0) neg0
        val max_nnan_pinf = test (negNan, posInf) posInf
        val max_nnan_ninf = test (negNan, negInf) negInf 
        val max_nnan_pnan = test (negNan, posNan) negNan
        val max_nnan_nnan = test (negNan, negNan) negNan
      in () end
  end (* local max *)

  (**********)

  local fun test arg expected = assertEqualInt expected (R.sign arg)
  in
  fun sign_normal () =
      let
        val sign_p = test 1.23 1
        val sign_n = test ~1.23 ~1
      in () end
  fun sign_zero () =
      let
        val sign_p0 = test pos0 0
        val sign_n0 = test neg0 0
      in () end
  fun sign_inf () =
      let
        val sign_pinf = test posInf 1
        val sign_ninf = test negInf ~1
      in () end
  fun sign_nan () =
      let
        val sign_pnan =
            (R.sign posNan; fail "sign posnan") handle General.Domain => ()
        val sign_nnan =
            (R.sign negNan; fail "sign negnan") handle General.Domain => ()
      in () end
  end (* local *)

  (**********)

  local fun test arg expected = assertEqualBool expected (R.signBit arg)
  in
  fun signBit_normal () =
      let
        val signBit_p = test 1.23 false
        val signBit_n = test ~1.23 true
      in () end
  fun signBit_zero () =
      let
        val signBit_p0 = test pos0 false
        val signBit_n0 = test neg0 true
      in () end
  fun signBit_inf () =
      let
        val signBit_pinf = test posInf false
        val signBit_ninf = test negInf true
      in () end
  fun signBit_nan () =
      let
        val signBit_pnan = test posNan false
        val signBit_nnan = test negNan true
      in () end
  end (* local *)

  (**********)

  local fun test arg expected = assertEqualBool expected (R.sameSign arg)
  in
  fun sameSign_normal () =
      let
        val sameSign_p_p = test (1.23, 2.34) true 
        val sameSign_p_n = test (1.23, ~2.34) false 
        val sameSign_p_p0 = test (1.23, pos0) true 
        val sameSign_p_n0 = test (1.23, neg0) false
        val sameSign_p_pinf = test (1.23, posInf) true 
        val sameSign_p_ninf = test (1.23, negInf) false
        val sameSign_p_pnan = test (1.23, posNan) true 
        val sameSign_p_nnan = test (1.23, negNan) false

        val sameSign_n_p = test (~1.23, 2.34) false 
        val sameSign_n_n = test (~1.23, ~2.34) true 
        val sameSign_n_p0 = test (~1.23, pos0) false 
        val sameSign_n_n0 = test (~1.23, neg0) true
        val sameSign_n_pinf = test (~1.23, posInf) false 
        val sameSign_n_ninf = test (~1.23, negInf) true
        val sameSign_n_pnan = test (~1.23, posNan) false 
        val sameSign_n_nnan = test (~1.23, negNan) true
      in () end
  fun sameSign_zero () =
      let
        val sameSign_p0_p = test (pos0, 2.34) true 
        val sameSign_p0_n = test (pos0, ~2.34) false 
        val sameSign_p0_p0 = test (pos0, pos0) true 
        val sameSign_p0_n0 = test (pos0, neg0) false
        val sameSign_p0_pinf = test (pos0, posInf) true 
        val sameSign_p0_ninf = test (pos0, negInf) false
        val sameSign_p0_pnan = test (pos0, posNan) true 
        val sameSign_p0_nnan = test (pos0, negNan) false

        val sameSign_n0_p = test (neg0, 2.34) false
        val sameSign_n0_n = test (neg0, ~2.34) true
        val sameSign_n0_p0 = test (neg0, pos0) false
        val sameSign_n0_n0 = test (neg0, neg0) true
        val sameSign_n0_pinf = test (neg0, posInf) false
        val sameSign_n0_ninf = test (neg0, negInf) true
        val sameSign_n0_pnan = test (neg0, posNan) false
        val sameSign_n0_nnan = test (neg0, negNan) true
      in () end
  fun sameSign_inf () =
      let
        val sameSign_pinf_p = test (posInf, 1.0) true
        val sameSign_pinf_n = test (posInf, ~1.0) false
        val sameSign_pinf_p0 = test (posInf, pos0) true
        val sameSign_pinf_n0 = test (posInf, neg0) false
        val sameSign_pinf_pinf = test (posInf, posInf) true
        val sameSign_pinf_ninf = test (posInf, negInf) false
        val sameSign_pinf_pnan = test (posInf, posNan) true
        val sameSign_pinf_nnan = test (posInf, negNan) false

        val sameSign_ninf_p = test (negInf, 1.0) false
        val sameSign_ninf_n = test (negInf, ~1.0) true
        val sameSign_ninf_p0 = test (negInf, pos0) false
        val sameSign_ninf_n0 = test (negInf, neg0) true
        val sameSign_ninf_pinf = test (negInf, posInf) false
        val sameSign_ninf_ninf = test (negInf, negInf) true
        val sameSign_ninf_pnan = test (negInf, posNan) false
        val sameSign_ninf_nnan = test (negInf, negNan) true
      in () end
  fun sameSign_nan () =
      let
        val sameSign_pnan_p = test (posNan, 1.0) true
        val sameSign_pnan_n = test (posNan, ~1.0) false
        val sameSign_pnan_p0 = test (posNan, pos0) true
        val sameSign_pnan_n0 = test (posNan, neg0) false
        val sameSign_pnan_pinf = test (posNan, posInf) true
        val sameSign_pnan_ninf = test (posNan, negInf) false
        val sameSign_pnan_pnan = test (posNan, posNan) true
        val sameSign_pnan_nnan = test (posNan, negNan) false

        val sameSign_nnan_p = test (negNan, 1.0) false
        val sameSign_nnan_n = test (negNan, ~1.0) true
        val sameSign_nnan_p0 = test (negNan, pos0) false
        val sameSign_nnan_n0 = test (negNan, neg0) true
        val sameSign_nnan_pinf = test (negNan, posInf) false
        val sameSign_nnan_ninf = test (negNan, negInf) true
        val sameSign_nnan_pnan = test (negNan, posNan) false
        val sameSign_nnan_nnan = test (negNan, negNan) true
      in () end

  end (* local *)
        
  (**********)

  local fun test arg expected = assertEqualReal expected (R.copySign arg)
  in
  fun copySign_pos () =
      let
        val copySign_p_p = test (1.23, 2.34) 1.23
        val copySign_p_n = test (1.23, ~2.34) ~1.23
        val copySign_p_p0 = test (1.23, pos0) 1.23
        val copySign_p_n0 = test (1.23, neg0) ~1.23
        val copySign_p_pinf = test (1.23, posInf) 1.23
        val copySign_p_ninf = test (1.23, negInf) ~1.23
        val copySign_p_pnan = test (1.23, posNan) 1.23
        val copySign_p_nnan = test (1.23, negNan) ~1.23
      in () end
  fun copySign_neg () =
      let
        val copySign_n_p = test (~1.23, 2.34) 1.23
        val copySign_n_n = test (~1.23, ~2.34) ~1.23
        val copySign_n_p0 = test (~1.23, pos0) 1.23
        val copySign_n_n0 = test (~1.23, neg0) ~1.23
        val copySign_n_pinf = test (~1.23, posInf) 1.23
        val copySign_n_ninf = test (~1.23, negInf) ~1.23
        val copySign_n_pnan = test (~1.23, posNan) 1.23
        val copySign_n_nnan = test (~1.23, negNan) ~1.23
      in () end
  fun copySign_p0 () =
      let
        val copySign_p0_p = test (pos0, 1.23) pos0
        val copySign_p0_n = test (pos0, ~1.23) neg0
        val copySign_p0_p0 = test (pos0, pos0) pos0
        val copySign_p0_n0 = test (pos0, neg0) neg0
        val copySign_p0_pinf = test (pos0, posInf) pos0
        val copySign_p0_ninf = test (pos0, negInf) neg0
        val copySign_p0_pnan = test (pos0, posNan) pos0
        val copySign_p0_nnan = test (pos0, negNan) neg0
      in () end
  fun copySign_n0 () =
      let
        val copySign_n0_p = test (neg0, 1.23) pos0
        val copySign_n0_n = test (neg0, ~1.23) neg0
        val copySign_n0_p0 = test (neg0, pos0) pos0
        val copySign_n0_n0 = test (neg0, neg0) neg0
        val copySign_n0_pinf = test (neg0, posInf) pos0
        val copySign_n0_ninf = test (neg0, negInf) neg0
        val copySign_n0_pnan = test (neg0, posNan) pos0
        val copySign_n0_nnan = test (neg0, negNan) neg0
      in () end
  fun copySign_pinf () =
      let
        val copySign_pinf_p = test (posInf, 1.23) posInf
        val copySign_pinf_n = test (posInf, ~1.23) negInf
        val copySign_pinf_p0 = test (posInf, pos0) posInf
        val copySign_pinf_n0 = test (posInf, neg0) negInf
        val copySign_pinf_pinf = test (posInf, posInf) posInf
        val copySign_pinf_ninf = test (posInf, negInf) negInf
        val copySign_pinf_pnan = test (posInf, posNan) posInf
        val copySign_pinf_nnan = test (posInf, negNan) negInf
      in () end
  fun copySign_ninf () =
      let
        val copySign_ninf_p = test (negInf, 1.23) posInf
        val copySign_ninf_n = test (negInf, ~1.23) negInf
        val copySign_ninf_p0 = test (negInf, pos0) posInf
        val copySign_ninf_n0 = test (negInf, neg0) negInf
        val copySign_ninf_pinf = test (negInf, posInf) posInf
        val copySign_ninf_ninf = test (negInf, negInf) negInf
        val copySign_ninf_pnan = test (negInf, posNan) posInf
        val copySign_ninf_nnan = test (negInf, negNan) negInf
      in () end
  fun copySign_pnan () =
      let
        val copySign_pnan_p = test (posNan, 1.23) posNan
        val copySign_pnan_n = test (posNan, ~1.23) negNan
        val copySign_pnan_p0 = test (posNan, pos0) posNan
        val copySign_pnan_n0 = test (posNan, neg0) negNan
        val copySign_pnan_pinf = test (posNan, posInf) posNan
        val copySign_pnan_ninf = test (posNan, negInf) negNan
        val copySign_pnan_pnan = test (posNan, posNan) posNan
        val copySign_pnan_nnan = test (posNan, negNan) negNan
      in () end
  fun copySign_nnan () =
      let
        val copySign_nnan_p = test (negNan, 1.23) posNan
        val copySign_nnan_n = test (negNan, ~1.23) negNan
        val copySign_nnan_p0 = test (negNan, pos0) posNan
        val copySign_nnan_n0 = test (negNan, neg0) negNan
        val copySign_nnan_pinf = test (negNan, posInf) posNan
        val copySign_nnan_ninf = test (negNan, negInf) negNan
        val copySign_nnan_pnan = test (negNan, posNan) posNan
        val copySign_nnan_nnan = test (negNan, negNan) negNan
      in () end

  end (* test *)

  (**********)

  local
    fun test arg expected = assertEqualOrder expected (R.compare arg)
    fun testFail input =
        (R.compare input; fail "compare_p_pnan") handle IR.Unordered => ()
  in
  fun compare_pos () =
      let
        val compare_p_p_l = test (1.23, 2.34) LESS
        val compare_p_p_e = test (1.23, 1.23) EQUAL
        val compare_p_p_g = test (2.34, 1.23) GREATER
        val compare_p_n = test (1.23, ~2.34) GREATER
        val compare_p_p0 = test (1.23, pos0) GREATER
        val compare_p_n0 = test (1.23, neg0) GREATER
        val compare_p_pinf = test (1.23, posInf) LESS
        val compare_p_ninf = test (1.23, negInf) GREATER
        val compare_p_pnan = testFail (1.23, posNan)
        val compare_p_nnan = testFail (1.23, negNan)
      in () end
  fun compare_neg () =
      let
        val compare_n_n_l = test (~2.34, ~1.23) LESS
        val compare_n_n_e = test (~2.34, ~2.34) EQUAL
        val compare_n_n_g = test (~1.23, ~2.34) GREATER
        val compare_n_p = test (~2.34, 1.23) LESS
        val compare_n_p0 = test (~1.23, pos0) LESS
        val compare_n_n0 = test (~1.23, neg0) LESS
        val compare_n_pinf = test (~1.23, posInf) LESS
        val compare_n_ninf = test (~1.23, negInf) GREATER
        val compare_n_pnan = testFail (~1.23, posNan) 
        val compare_n_nnan = testFail (~1.23, negNan)
      in () end
  fun compare_p0 () =
      let
        val compare_p0_p = test (pos0, 1.23) LESS
        val compare_p0_n = test (pos0, ~1.23) GREATER
        val compare_p0_p0 = test (pos0, pos0) EQUAL
        val compare_p0_n0 = test (pos0, neg0) EQUAL
        val compare_p0_pinf = test (pos0, posInf) LESS
        val compare_p0_ninf = test (pos0, negInf) GREATER
        val compare_p0_pnan = testFail (pos0, posNan) 
        val compare_p0_nnan = testFail (pos0, negNan)
      in () end
  fun compare_n0 () =
      let
        val compare_n0_p = test (neg0, 1.23) LESS
        val compare_n0_n = test (neg0, ~1.23) GREATER
        val compare_n0_p0 = test (neg0, pos0) EQUAL
        val compare_n0_n0 = test (neg0, neg0) EQUAL
        val compare_n0_pinf = test (neg0, posInf) LESS
        val compare_n0_ninf = test (neg0, negInf) GREATER
        val compare_n0_pnan = testFail (neg0, posNan)
        val compare_n0_nnan = testFail (neg0, negNan)
      in () end
  fun compare_pinf () =
      let
        val compare_pinf_p = test (posInf, 1.23) GREATER
        val compare_pinf_n = test (posInf, ~1.23) GREATER
        val compare_pinf_p0 = test (posInf, pos0) GREATER
        val compare_pinf_n0 = test (posInf, neg0) GREATER
        val compare_pinf_pinf = test (posInf, posInf) EQUAL
        val compare_pinf_ninf = test (posInf, negInf) GREATER
        val compare_pinf_pnan = testFail (posInf, posNan)
        val compare_pinf_nnan = testFail (posInf, negNan)
      in () end
  fun compare_ninf () =
      let
        val compare_ninf_p = test (negInf, 1.23) LESS
        val compare_ninf_n = test (negInf, ~1.23) LESS
        val compare_ninf_p0 = test (negInf, pos0) LESS
        val compare_ninf_n0 = test (negInf, neg0) LESS
        val compare_ninf_pinf = test (negInf, posInf) LESS
        val compare_ninf_ninf = test (negInf, negInf) EQUAL
        val compare_ninf_pnan = testFail (negInf, posNan)
        val compare_ninf_nnan = testFail (negInf, negNan)
      in () end
  fun compare_pnan () =
      let
        val compare_pnan_p = testFail (posNan, 1.23)
        val compare_pnan_n = testFail (posNan, ~1.23)
        val compare_pnan_p0 = testFail (posNan, pos0)
        val compare_pnan_n0 = testFail (posNan, neg0)
        val compare_pnan_pinf = testFail (posNan, posInf)
        val compare_pnan_ninf = testFail (posNan, negInf)
        val compare_pnan_pnan = testFail (posNan, posNan)
        val compare_pnan_nnan = testFail (posNan, negNan)
      in () end
  fun compare_nnan () =
      let
        val compare_nnan_p = testFail (negNan, 1.23)
        val compare_nnan_n = testFail (negNan, ~1.23)
        val compare_nnan_p0 = testFail (negNan, pos0)
        val compare_nnan_n0 = testFail (negNan, neg0)
        val compare_nnan_pinf = testFail (negNan, posInf)
        val compare_nnan_ninf = testFail (negNan, negInf)
        val compare_nnan_pnan = testFail (negNan, posNan)
        val compare_nnan_nnan = testFail (negNan, negNan)
      in () end
  end (* local *)

  (**********)

  local
    fun test arg expected = assertEqualRealOrder expected (R.compareReal arg)
  in
  fun compareReal_pos () =
      let
        val compareReal_p_p_l = test (1.23, 2.34) IR.LESS
        val compareReal_p_p_e = test (1.23, 1.23) IR.EQUAL
        val compareReal_p_p_g = test (2.34, 1.23) IR.GREATER
        val compareReal_p_n = test (1.23, ~2.34) IR.GREATER
        val compareReal_p_p0 = test (1.23, pos0) IR.GREATER
        val compareReal_p_n0 = test (1.23, neg0) IR.GREATER
        val compareReal_p_pinf = test (1.23, posInf) IR.LESS
        val compareReal_p_ninf = test (1.23, negInf) IR.GREATER
        val compareReal_p_pnan = test (1.23, posNan) IR.UNORDERED
        val compareReal_p_nnan = test (1.23, negNan) IR.UNORDERED
      in () end
  fun compareReal_neg () =
      let
        val compareReal_n_n_l = test (~2.34, ~1.23) IR.LESS
        val compareReal_n_n_e = test (~2.34, ~2.34) IR.EQUAL
        val compareReal_n_n_g = test (~1.23, ~2.34) IR.GREATER
        val compareReal_n_p = test (~2.34, 1.23) IR.LESS
        val compareReal_n_p0 = test (~1.23, pos0) IR.LESS
        val compareReal_n_n0 = test (~1.23, neg0) IR.LESS
        val compareReal_n_pinf = test (~1.23, posInf) IR.LESS
        val compareReal_n_ninf = test (~1.23, negInf) IR.GREATER
        val compareReal_n_pnan = test (~1.23, posNan)  IR.UNORDERED
        val compareReal_n_nnan = test (~1.23, negNan) IR.UNORDERED
      in () end
  fun compareReal_p0 () =
      let
        val compareReal_p0_p = test (pos0, 1.23) IR.LESS
        val compareReal_p0_n = test (pos0, ~1.23) IR.GREATER
        val compareReal_p0_p0 = test (pos0, pos0) IR.EQUAL
        val compareReal_p0_n0 = test (pos0, neg0) IR.EQUAL
        val compareReal_p0_pinf = test (pos0, posInf) IR.LESS
        val compareReal_p0_ninf = test (pos0, negInf) IR.GREATER
        val compareReal_p0_pnan = test (pos0, posNan)  IR.UNORDERED
        val compareReal_p0_nnan = test (pos0, negNan) IR.UNORDERED
      in () end
  fun compareReal_n0 () =
      let
        val compareReal_n0_p = test (neg0, 1.23) IR.LESS
        val compareReal_n0_n = test (neg0, ~1.23) IR.GREATER
        val compareReal_n0_p0 = test (neg0, pos0) IR.EQUAL
        val compareReal_n0_n0 = test (neg0, neg0) IR.EQUAL
        val compareReal_n0_pinf = test (neg0, posInf) IR.LESS
        val compareReal_n0_ninf = test (neg0, negInf) IR.GREATER
        val compareReal_n0_pnan = test (neg0, posNan) IR.UNORDERED
        val compareReal_n0_nnan = test (neg0, negNan) IR.UNORDERED
      in () end
  fun compareReal_pinf () =
      let
        val compareReal_pinf_p = test (posInf, 1.23) IR.GREATER
        val compareReal_pinf_n = test (posInf, ~1.23) IR.GREATER
        val compareReal_pinf_p0 = test (posInf, pos0) IR.GREATER
        val compareReal_pinf_n0 = test (posInf, neg0) IR.GREATER
        val compareReal_pinf_pinf = test (posInf, posInf) IR.EQUAL
        val compareReal_pinf_ninf = test (posInf, negInf) IR.GREATER
        val compareReal_pinf_pnan = test (posInf, posNan) IR.UNORDERED
        val compareReal_pinf_nnan = test (posInf, negNan) IR.UNORDERED
      in () end
  fun compareReal_ninf () =
      let
        val compareReal_ninf_p = test (negInf, 1.23) IR.LESS
        val compareReal_ninf_n = test (negInf, ~1.23) IR.LESS
        val compareReal_ninf_p0 = test (negInf, pos0) IR.LESS
        val compareReal_ninf_n0 = test (negInf, neg0) IR.LESS
        val compareReal_ninf_pinf = test (negInf, posInf) IR.LESS
        val compareReal_ninf_ninf = test (negInf, negInf) IR.EQUAL
        val compareReal_ninf_pnan = test (negInf, posNan) IR.UNORDERED
        val compareReal_ninf_nnan = test (negInf, negNan) IR.UNORDERED
      in () end
  fun compareReal_pnan () =
      let
        val compareReal_pnan_p = test (posNan, 1.23) IR.UNORDERED
        val compareReal_pnan_n = test (posNan, ~1.23) IR.UNORDERED
        val compareReal_pnan_p0 = test (posNan, pos0) IR.UNORDERED
        val compareReal_pnan_n0 = test (posNan, neg0) IR.UNORDERED
        val compareReal_pnan_pinf = test (posNan, posInf) IR.UNORDERED
        val compareReal_pnan_ninf = test (posNan, negInf) IR.UNORDERED
        val compareReal_pnan_pnan = test (posNan, posNan) IR.UNORDERED
        val compareReal_pnan_nnan = test (posNan, negNan) IR.UNORDERED
      in () end
  fun compareReal_nnan () =
      let
        val compareReal_nnan_p = test (negNan, 1.23) IR.UNORDERED
        val compareReal_nnan_n = test (negNan, ~1.23) IR.UNORDERED
        val compareReal_nnan_p0 = test (negNan, pos0) IR.UNORDERED
        val compareReal_nnan_n0 = test (negNan, neg0) IR.UNORDERED
        val compareReal_nnan_pinf = test (negNan, posInf) IR.UNORDERED
        val compareReal_nnan_ninf = test (negNan, negInf) IR.UNORDERED
        val compareReal_nnan_pnan = test (negNan, posNan) IR.UNORDERED
        val compareReal_nnan_nnan = test (negNan, negNan) IR.UNORDERED
      in () end

  end (* local *)

  (**********)

  local (* outer local *)
    val TTTT = (true, true, true, true)
    val TTFF = (true, true, false, false)
    val TFTF = (true, false, true, false)
    val FTTT = (false, true, true, true)
    val FTTF = (false, true, true, false)
    val FTFF = (false, true, false, false)
    val FFTT = (false, false, true, true)
    val FFFF = (false, false, false, false)
  in
  local (* inner local *)
    fun test args expected =
        assertEqual4Bool expected (R.< args, R.<= args, R.>= args, R.> args)
  in
  fun binComp_pos () =
      let
        val binComp_p_p_l = test (1.23, 2.34) TTFF
        val binComp_p_p_g = test (2.34, 1.23) FFTT
        val binComp_p_p_e = test (1.23, 1.23) FTTF
        val binComp_p_n = test (1.23, ~2.34) FFTT
        val binComp_p_p0 = test (1.23, pos0) FFTT
        val binComp_p_n0 = test (1.23, neg0) FFTT
        val binComp_p_pinf = test (1.23, posInf) TTFF
        val binComp_p_ninf = test (1.23, negInf) FFTT
        val binComp_p_pnan = test (1.23, posNan) FFFF
        val binComp_p_nnan = test (1.23, negNan) FFFF
      in () end
  fun binComp_neg () =
      let
        val binComp_n_n_l = test (~2.34, ~1.23) TTFF
        val binComp_n_n_g = test (~1.23, ~2.34) FFTT
        val binComp_n_n_e = test (~2.34, ~2.34) FTTF
        val binComp_n_p = test (~2.34, 1.23) TTFF
        val binComp_n_p0 = test (~1.23, pos0) TTFF
        val binComp_n_n0 = test (~1.23, neg0) TTFF
        val binComp_n_pinf = test (~1.23, posInf) TTFF
        val binComp_n_ninf = test (~1.23, negInf) FFTT
        val binComp_n_pnan = test (~1.23, posNan) FFFF
        val binComp_n_nnan = test (~1.23, negNan) FFFF
      in () end
  fun binComp_p0 () =
      let
        val binComp_p0_n = test (pos0, ~1.23) FFTT
        val binComp_p0_p = test (pos0, 1.23) TTFF
        val binComp_p0_p0 = test (pos0, pos0) FTTF
        val binComp_p0_n0 = test (pos0, neg0) FTTF
        val binComp_p0_pinf = test (pos0, posInf) TTFF
        val binComp_p0_ninf = test (pos0, negInf) FFTT
        val binComp_p0_pnan = test (pos0, posNan) FFFF
        val binComp_p0_nnan = test (pos0, negNan) FFFF
      in () end
  fun binComp_n0 () =
      let
        val binComp_n0_n = test (neg0, ~1.23) FFTT
        val binComp_n0_p = test (neg0, 1.23) TTFF
        val binComp_n0_p0 = test (neg0, pos0) FTTF
        val binComp_n0_n0 = test (neg0, neg0) FTTF
        val binComp_n0_pinf = test (neg0, posInf) TTFF
        val binComp_n0_ninf = test (neg0, negInf) FFTT
        val binComp_n0_pnan = test (neg0, posNan) FFFF
        val binComp_n0_nnan = test (neg0, negNan) FFFF
      in () end
  fun binComp_pinf () =
      let
        val binComp_pinf_n = test (posInf, ~1.23) FFTT
        val binComp_pinf_p = test (posInf, 1.23) FFTT
        val binComp_pinf_p0 = test (posInf, pos0) FFTT
        val binComp_pinf_n0 = test (posInf, neg0) FFTT
        val binComp_pinf_pinf = test (posInf, posInf) FTTF
        val binComp_pinf_ninf = test (posInf, negInf) FFTT
        val binComp_pinf_pnan = test (posInf, posNan) FFFF
        val binComp_pinf_nnan = test (posInf, negNan) FFFF
      in () end
  fun binComp_ninf () =
      let
        val binComp_ninf_n = test (negInf, ~1.23) TTFF
        val binComp_ninf_p = test (negInf, 1.23) TTFF
        val binComp_ninf_p0 = test (negInf, pos0) TTFF
        val binComp_ninf_n0 = test (negInf, neg0) TTFF
        val binComp_ninf_pinf = test (negInf, posInf) TTFF
        val binComp_ninf_ninf = test (negInf, negInf) FTTF
        val binComp_ninf_pnan = test (negInf, posNan) FFFF
        val binComp_ninf_nnan = test (negInf, negNan) FFFF
      in () end
  fun binComp_pnan () =
      let
        val binComp_pnan_n = test (posNan, ~1.23) FFFF
        val binComp_pnan_p = test (posNan, 1.23) FFFF
        val binComp_pnan_pnan = test (posNan, posNan) FFFF
        val binComp_pnan_nnan = test (posNan, negNan) FFFF
        val binComp_pnan_pinf = test (posNan, posInf) FFFF
        val binComp_pnan_ninf = test (posNan, negInf) FFFF
        val binComp_pnan_pnan = test (posNan, posNan) FFFF
        val binComp_pnan_nnan = test (posNan, negNan) FFFF
      in () end
  fun binComp_nnan () =
      let
        val binComp_nnan_n = test (negNan, ~1.23) FFFF
        val binComp_nnan_p = test (negNan, 1.23) FFFF
        val binComp_nnan_pnan = test (negNan, posNan) FFFF
        val binComp_nnan_nnan = test (negNan, negNan) FFFF
        val binComp_nnan_pinf = test (negNan, posInf) FFFF
        val binComp_nnan_ninf = test (negNan, negInf) FFFF
        val binComp_nnan_pnan = test (negNan, posNan) FFFF
        val binComp_nnan_nnan = test (negNan, negNan) FFFF
      in () end
  end (* inner local *)

  (**********)

  local
    fun test args expected =
        assertEqual4Bool
            expected (R.== args, R.!= args, R.?= args, R.unordered args)
  in
  fun IEEEEq_pos () =
      let
        val IEEEEq_p_p_l = test (1.23, 2.34) FTFF
        val IEEEEq_p_p_g = test (2.34, 1.23) FTFF
        val IEEEEq_p_p_e = test (1.23, 1.23) TFTF
        val IEEEEq_p_n = test (1.23, ~2.34) FTFF
        val IEEEEq_p_p0 = test (1.23, pos0) FTFF
        val IEEEEq_p_n0 = test (1.23, neg0) FTFF
        val IEEEEq_p_pinf = test (1.23, posInf) FTFF
        val IEEEEq_p_ninf = test (1.23, negInf) FTFF
        val IEEEEq_p_pnan = test (1.23, posNan) FTTT
        val IEEEEq_p_nnan = test (1.23, negNan) FTTT
      in () end
  fun IEEEEq_neg () =
      let
        val IEEEEq_n_n_l = test (~2.34, ~1.23) FTFF
        val IEEEEq_n_n_g = test (~1.23, ~2.34) FTFF
        val IEEEEq_n_n_e = test (~2.34, ~2.34) TFTF
        val IEEEEq_n_p = test (~2.34, 1.23) FTFF
        val IEEEEq_n_p0 = test (~1.23, pos0) FTFF
        val IEEEEq_n_n0 = test (~1.23, neg0) FTFF
        val IEEEEq_n_pinf = test (~1.23, posInf) FTFF
        val IEEEEq_n_ninf = test (~1.23, negInf) FTFF
        val IEEEEq_n_pnan = test (~1.23, posNan) FTTT
        val IEEEEq_n_nnan = test (~1.23, negNan) FTTT
      in () end
  fun IEEEEq_p0 () =
      let
        val IEEEEq_p0_n = test (pos0, ~1.23) FTFF
        val IEEEEq_p0_p = test (pos0, 1.23) FTFF
        val IEEEEq_p0_p0 = test (pos0, pos0) TFTF
        val IEEEEq_p0_n0 = test (pos0, neg0) TFTF
        val IEEEEq_p0_pinf = test (pos0, posInf) FTFF
        val IEEEEq_p0_ninf = test (pos0, negInf) FTFF
        val IEEEEq_p0_pnan = test (pos0, posNan) FTTT
        val IEEEEq_p0_nnan = test (pos0, negNan) FTTT
      in () end
  fun IEEEEq_n0 () =
      let
        val IEEEEq_n0_n = test (neg0, ~1.23) FTFF
        val IEEEEq_n0_p = test (neg0, 1.23) FTFF
        val IEEEEq_n0_p0 = test (neg0, pos0) TFTF
        val IEEEEq_n0_n0 = test (neg0, neg0) TFTF
        val IEEEEq_n0_pinf = test (neg0, posInf) FTFF
        val IEEEEq_n0_ninf = test (neg0, negInf) FTFF
        val IEEEEq_n0_pnan = test (neg0, posNan) FTTT
        val IEEEEq_n0_nnan = test (neg0, negNan) FTTT
      in () end
  fun IEEEEq_pinf () =
      let
        val IEEEEq_pinf_n = test (posInf, ~1.23) FTFF
        val IEEEEq_pinf_p = test (posInf, 1.23) FTFF
        val IEEEEq_pinf_p0 = test (posInf, pos0) FTFF
        val IEEEEq_pinf_n0 = test (posInf, neg0) FTFF
        val IEEEEq_pinf_pinf = test (posInf, posInf) TFTF
        val IEEEEq_pinf_ninf = test (posInf, negInf) FTFF
        val IEEEEq_pinf_pnan = test (posInf, posNan) FTTT
        val IEEEEq_pinf_nnan = test (posInf, negNan) FTTT
      in () end
  fun IEEEEq_ninf () =
      let
        val IEEEEq_ninf_n = test (negInf, ~1.23) FTFF
        val IEEEEq_ninf_p = test (negInf, 1.23) FTFF
        val IEEEEq_ninf_p0 = test (negInf, pos0) FTFF
        val IEEEEq_ninf_n0 = test (negInf, neg0) FTFF
        val IEEEEq_ninf_pinf = test (negInf, posInf) FTFF
        val IEEEEq_ninf_ninf = test (negInf, negInf) TFTF
        val IEEEEq_ninf_pnan = test (negInf, posNan) FTTT
        val IEEEEq_ninf_nnan = test (negInf, negNan) FTTT
      in () end
  fun IEEEEq_pnan () =
      let
        val IEEEEq_pnan_n = test (posNan, ~1.23) FTTT
        val IEEEEq_pnan_p = test (posNan, 1.23) FTTT
        val IEEEEq_pnan_pnan = test (posNan, posNan) FTTT
        val IEEEEq_pnan_nnan = test (posNan, negNan) FTTT
        val IEEEEq_pnan_pinf = test (posNan, posInf) FTTT
        val IEEEEq_pnan_ninf = test (posNan, negInf) FTTT
        val IEEEEq_pnan_pnan = test (posNan, posNan) FTTT
        val IEEEEq_pnan_nnan = test (posNan, negNan) FTTT
      in () end
  fun IEEEEq_nnan () =
      let
        val IEEEEq_nnan_n = test (negNan, ~1.23) FTTT
        val IEEEEq_nnan_p = test (negNan, 1.23) FTTT
        val IEEEEq_nnan_pnan = test (negNan, posNan) FTTT
        val IEEEEq_nnan_nnan = test (negNan, negNan) FTTT
        val IEEEEq_nnan_pinf = test (negNan, posInf) FTTT
        val IEEEEq_nnan_ninf = test (negNan, negInf) FTTT
        val IEEEEq_nnan_pnan = test (negNan, posNan) FTTT
        val IEEEEq_nnan_nnan = test (negNan, negNan) FTTT
      in () end
  end (* inner local *)

  end (* outer local *)

  (**********)

  local fun test arg expected = assertEqualBool expected (R.isFinite arg)
  in
  fun isFinite001 () =
      let
        val isFinite_p = test 1.23 true
        val isFinite_n = test ~2.34 true
        val isFinite_p0 = test pos0 true
        val isFinite_n0 = test neg0 true
        val isFinite_pinf = test posInf false
        val isFinite_ninf = test negInf false
        val isFinite_pnan = test posNan false
        val isFinite_nnan = test negNan false
      in () end
  end

  (**********)

  local fun test arg expected = assertEqualBool expected (R.isNan arg)
  in
  fun isNan001 () =
      let
        val isNan_p = test 1.23 false
        val isNan_n = test ~2.34 false
        val isNan_p0 = test pos0 false
        val isNan_n0 = test neg0 false
        val isNan_pinf = test posInf false
        val isNan_ninf = test negInf false
        val isNan_pnan = test posNan true
        val isNan_nnan = test negNan true
      in () end
  end

  (**********)

  local fun test arg expected = assertEqualBool expected (R.isNormal arg)
  in
  fun isNormal001 () =
      let
        val isNormal_p = test 1.23 true
        val isNormal_n = test ~2.34 true
        val isNormal_p0 = test pos0 false
        val isNormal_n0 = test neg0 false
        val isNormal_pinf = test posInf false
        val isNormal_ninf = test negInf false
        val isNormal_pnan = test posNan false
        val isNormal_nnan = test negNan false
      in () end
  end

  (**********)

  local fun test arg expected = assertEqualFloatClass expected (R.class arg)
  in
  fun class001 () =
      let
        (* ToDo : how to test SUBNORMAL ? *)
        val class_p = test 1.23 IR.NORMAL
        val class_n = test ~2.34 IR.NORMAL
        val class_p0 = test pos0 IR.ZERO
        val class_n0 = test neg0 IR.ZERO
        val class_pinf = test posInf IR.INF
        val class_ninf = test negInf IR.INF
        val class_pnan = test posNan IR.NAN
        val class_nnan = test negNan IR.NAN
      in () end
  end

  (**********)

  local
    fun test arg expected = assertEqualManExp expected (R.toManExp arg)
    (* On infinity and nan, exp field of return values is unspecified. *)
    fun testAbnormal arg expected =
        assertEqualReal expected (#man (R.toManExp arg))
  in
  fun toManExp001 () =
      let
        (* The 'man' field of return value of toManExp is
         *   1.0/radix <= abs(man) < 1.0
         * If radix = 2, the absolute of 'man' is in [0.5, 1.0), for example.
         *)
        val toManExp_p =
            test (0.567 * R.fromInt R.radix) {man = 0.567, exp = 1}
        val toManExp_n =
            test (~0.567 * R.fromInt R.radix) {man = ~0.567, exp = 1}
        val toManExp_p0 = test pos0 {man = pos0, exp = 0}
        val toManExp_n0 = test neg0 {man = neg0, exp = 0}

        val toManExp_pinf = testAbnormal posInf posInf
        val toManExp_ninf = testAbnormal negInf negInf
        val toManExp_pnan = testAbnormal posNan posNan
        val toManExp_nnan = testAbnormal negNan negNan
      in () end
  end (* local *)

  (**********)

  local fun test arg expected = assertEqualReal expected (R.fromManExp arg)
  in
  fun fromManExp001 () =
      let
        val fromManExp_p0_0 = test {man = pos0, exp = 0} pos0
        val fromManExp_p0_p = test {man = pos0, exp = 4} pos0
        val fromManExp_p0_n = test {man = pos0, exp = ~4} pos0

        val fromManExp_n0_0 = test {man = neg0, exp = 0} neg0
        val fromManExp_n0_p = test {man = neg0, exp = 4} neg0
        val fromManExp_n0_n = test {man = neg0, exp = ~4} neg0

        val fromManExp_p_0 = test {man = 12.3, exp = 0} 12.3
        val fromManExp_p_p =
            test
                {man = 12.3, exp = 4}
                (12.3 * Math.pow(R.fromInt R.radix, 4.0))
        val fromManExp_p_n =
            test
                {man = 12.3, exp = ~4}
                (12.3 * Math.pow(R.fromInt R.radix, ~4.0))
        val fromManExp_n_0 = test {man = ~12.3, exp = 0} ~12.3
        val fromManExp_n_p =
            test
                {man = ~12.3, exp = 4}
                (~12.3 * Math.pow(R.fromInt R.radix, 4.0))
        val fromManExp_n_n =
            test
                {man = ~12.3, exp = ~4}
                (~12.3 * Math.pow(R.fromInt R.radix, ~4.0))
        val fromManExp_pinf_0 = test {man = posInf, exp = 0} posInf
        val fromManExp_pinf_p = test {man = posInf, exp = 4} posInf
        val fromManExp_pinf_n = test {man = posInf, exp = ~4} posInf

        val fromManExp_ninf_0 = test {man = negInf, exp = 0} negInf
        val fromManExp_ninf_p = test {man = negInf, exp = 4} negInf
        val fromManExp_ninf_n = test {man = negInf, exp = ~4} negInf

        val fromManExp_pnan_0 = test {man = posNan, exp = 0} posNan
        val fromManExp_pnan_p = test {man = posNan, exp = 4} posNan
        val fromManExp_pnan_n = test {man = posNan, exp = ~4} posNan

        val fromManExp_nnan_0 = test {man = negNan, exp = 0} negNan
        val fromManExp_nnan_p = test {man = negNan, exp = 4} negNan
        val fromManExp_nnan_n = test {man = negNan, exp = ~4} negNan
      in () end
  end (* local *)

  (**********)

  local fun test arg expected = assertEqualWholeFrac expected (R.split arg)
  in
  fun split001 () =
      let
        val split_p = test 123.456 {whole = 123.0, frac = 0.456}
        val split_n = test ~123.456 {whole = ~123.0, frac = ~0.456}
        val split_p0 = test pos0 {whole = pos0, frac = pos0}
        val split_n0 = test neg0 {whole = neg0, frac = neg0}
        (* If r is +-infinity, whole is +-infinity and frac is +-0. *)
        val split_pinf = test posInf {whole = posInf, frac = pos0}
        val split_ninf = test negInf {whole = negInf, frac = neg0}
        (* If r is NaN, both whole and frac are NaN. *)
        val split_pnan = test posNan {whole = posNan, frac = posNan}
        val split_nnan = test negNan {whole = negNan, frac = negNan}
      in () end
  end (* local *)

  (**********)

  local fun test arg expected = assertEqualReal expected (R.realMod arg)
  in
  fun realMod001 () =
      let
        val realMod_p = test 123.456 0.456
        val realMod_n = test ~123.456 ~0.456
        val realMod_p0 = test pos0 pos0
        val realMod_n0 = test neg0 neg0
        val realMod_pinf = test posInf pos0
        val realMod_ninf = test negInf neg0
        val realMod_pnan = test posNan posNan
        val realMod_nnan = test negNan negNan
      in () end
  end (* local *)

  (**********)

  local
    fun testNormal (arg1, arg2) expected =
        let
          val r = R.nextAfter (arg1, arg2)
          val _ = assertEqualOrder expected (Real.compare(r, arg1))
        in () end
    fun testAbnormal (arg1, arg2) expected =
        assertEqualReal expected (R.nextAfter (arg1, arg2))
  in
  fun nextAfter001 () =
      let
        val nextAfter_p_l = testNormal (1.23, 1.0) LESS
        val nextAfter_p_e = testNormal (1.23, 1.23) EQUAL
        val nextAfter_p_g = testNormal (1.23, 2.0) GREATER
        val nextAfter_n_l = testNormal (~1.23, ~2.0) LESS
        val nextAfter_n_e = testNormal (~1.23, ~1.23) EQUAL
        val nextAfter_n_g = testNormal (~1.23, ~1.0) GREATER
        val nextAfter_p0_l = testNormal (pos0, ~1.0) LESS
        val nextAfter_p0_e = testNormal (pos0, pos0) EQUAL
        val nextAfter_p0_g = testNormal (pos0, 1.0) GREATER
        val nextAfter_n0_l = testNormal (neg0, ~1.0) LESS
        val nextAfter_n0_e = testNormal (neg0, neg0) EQUAL
        val nextAfter_n0_g = testNormal (neg0, 1.0) GREATER

        val nextAfter_pinf = testAbnormal (posInf, 0.0) posInf
        val nextAfter_ninf = testAbnormal (negInf, 0.0) negInf
        val nextAfter_pnan = testAbnormal (posNan, 0.0) posNan
        val nextAfter_nnan = testAbnormal (negNan, 0.0) negNan
      in () end
  end

  (**********)

  local
    fun test arg expected = assertEqualReal expected (R.checkFloat arg)
    fun testFailByOverflow arg =
        (R.checkFloat arg; fail "checkFloat:Overflow expected.")
        handle General.Overflow => ()
    fun testFailByDiv arg =
        (R.checkFloat arg; fail "checkFloat:Div expected.")
        handle General.Div => ()
  in
  fun checkFloat001 () =
      let
        val checkFloat_p = test 1.23 1.23
        val checkFloat_n = test ~2.34 ~2.34
        val checkFloat_p0 = test pos0 pos0
        val checkFloat_n0 = test neg0 neg0

        val checkFloat_pinf = testFailByOverflow posInf
        val checkFloat_ninf = testFailByOverflow negInf

        val checkFloat_pnan = testFailByDiv posNan
        val checkFloat_nnan = testFailByDiv negNan
            handle General.Div => ()
      in () end
  end (* local *)

  (**********)

  local
    fun test args expected =
        assertEqual4Real
            expected
            (
              R.realFloor args,
              R.realCeil args,
              R.realTrunc args,
              R.realRound args
            )
  in
  fun toRealIntConversions0001 () =
      let
        val conv_p_14 = test 1.4 (1.0, 2.0, 1.0, 1.0)
        val conv_p_15 = test 1.5 (1.0, 2.0, 1.0, 2.0)
        val conv_n_14 = test ~1.4 (~2.0, ~1.0, ~1.0, ~1.0)
        val conv_n_15 = test ~1.5 (~2.0, ~1.0, ~1.0, ~2.0)

        val conv_p0 = test pos0 (pos0, pos0, pos0, pos0)
        val conv_n0 = test neg0 (neg0, neg0, neg0, neg0)
        val conv_pInf = test posInf (posInf, posInf, posInf, posInf)
        val conv_nInf = test negInf (negInf, negInf, negInf, negInf)
        val conv_pNan = test posNan (posNan, posNan, posNan, posNan)
        val conv_nNan = test negNan (negNan, negNan, negNan, negNan)
      in () end
  end (* local *)

  (**********)

  local
    fun test args expected =
        assertEqual4Int
            expected (R.floor args, R.ceil args, R.trunc args, R.round args)
  in
  fun toIntConversions_normal_0001 () =
      let
        val conv_p_14 = test 1.4 (1, 2, 1, 1)
        val conv_p_15 = test 1.5 (1, 2, 1, 2)
        val conv_n_14 = test ~1.4 (~2, ~1, ~1, ~1)
        val conv_n_15 = test ~1.5 (~2, ~1, ~1, ~2)

        val conv_p0 = test pos0 (0, 0, 0, 0)
        val conv_n0 = test neg0 (0, 0, 0, 0)
      in () end
  end (* local *)

  local
    fun test conv arg expected = assertEqualInt expected (conv arg)
    fun testFail conv arg =
        (conv arg; fail "Overflow expected") handle General.Overflow => ()
  in
  fun toIntConversions_normal_1001 () =
      let
        (* all conversions fail. *)
        val maxIntPlus1_r = maxInt_r + 1.0
        val minIntMinus1_r = minInt_r - 1.0

        val conv_pinf_floor = testFail R.floor maxIntPlus1_r
        val conv_pinf_ceil = testFail R.ceil maxIntPlus1_r
        val conv_pinf_trunc = testFail R.trunc maxIntPlus1_r
        val conv_pinf_round = testFail R.round maxIntPlus1_r

        val conv_ninf_floor = testFail R.floor minIntMinus1_r
        val conv_ninf_ceil = testFail R.ceil minIntMinus1_r
        val conv_ninf_trunc = testFail R.trunc minIntMinus1_r
        val conv_ninf_round = testFail R.round minIntMinus1_r
      in () end
  fun toIntConversions_normal_1002 () =
      let
        (* round succeeds. *)
        val maxIntPlus04_r = maxInt_r + 0.4
        val minIntMinus04_r = minInt_r - 0.4

        val conv_pinf_floor = test R.floor maxIntPlus04_r maxInt
        val conv_pinf_ceil = testFail R.ceil maxIntPlus04_r
        val conv_pinf_trunc = test R.trunc maxIntPlus04_r maxInt
        val conv_pinf_round = test R.round maxIntPlus04_r maxInt

        val conv_ninf_floor = testFail R.floor minIntMinus04_r
        val conv_ninf_ceil = test R.ceil minIntMinus04_r minInt
        val conv_ninf_trunc = test R.trunc minIntMinus04_r minInt
        val conv_ninf_round = test R.round minIntMinus04_r minInt
      in () end
  fun toIntConversions_normal_1003 () =
      let
        (* round fails *)
        val maxIntPlus06_r = maxInt_r + 0.6
        val minIntMinus06_r = minInt_r - 0.6

        val conv_pinf_floor = test R.floor maxIntPlus06_r maxInt
        val conv_pinf_ceil = testFail R.ceil maxIntPlus06_r
        val conv_pinf_trunc = test R.trunc maxIntPlus06_r maxInt
        val conv_pinf_round = testFail R.round maxIntPlus06_r

        val conv_ninf_floor = testFail R.floor minIntMinus06_r
        val conv_ninf_ceil = test R.ceil minIntMinus06_r minInt
        val conv_ninf_trunc = test R.trunc minIntMinus06_r minInt
        val conv_ninf_round = testFail R.round minIntMinus06_r
      in () end
  end (* local *)

  local
    fun testFail conv arg =
        (conv arg; fail "Overflow expected") handle General.Overflow => ()
  in
  fun toIntConversions_inf () =
      let
        val conv_pinf_floor = testFail R.floor posInf
        val conv_pinf_ceil = testFail R.ceil posInf
        val conv_pinf_trunc = testFail R.trunc posInf
        val conv_pinf_round = testFail R.round posInf

        val conv_ninf_floor = testFail R.floor negInf
        val conv_ninf_ceil = testFail R.ceil negInf
        val conv_ninf_trunc = testFail R.trunc negInf
        val conv_ninf_round = testFail R.round negInf
      in () end
  end (* local *)

  local
    fun testFail conv arg =
        (conv arg; fail "Domain expected") handle General.Domain => ()
  in
  fun toIntConversions_nan () =
      let
        val conv_pnan_floor = testFail R.floor posNan
        val conv_pnan_ceil = testFail R.ceil posNan
        val conv_pnan_trunc = testFail R.trunc posNan
        val conv_pnan_round = testFail R.round posNan

        val conv_nnan_floor = testFail R.floor negNan
        val conv_nnan_ceil = testFail R.ceil negNan
        val conv_nnan_trunc = testFail R.trunc negNan
        val conv_nnan_round = testFail R.round negNan
      in () end
  end (* local *)

  (**********)

  local
    fun test arg expected =
        assertEqual4Int
            expected
            (
              R.toInt IR.TO_NEAREST arg,
              R.toInt IR.TO_NEGINF arg,
              R.toInt IR.TO_POSINF arg,
              R.toInt IR.TO_ZERO arg
            )
  in
  fun toInt_normal_0001 () =
      let
        val normal_p14 = test 1.4 (1, 1, 2, 1)
        val normal_p15 = test 1.5 (2, 1, 2, 1)
        val normal_n14 = test ~1.4 (~1, ~2, ~1, ~1)
        val normal_n15 = test ~1.5 (~2, ~2, ~1, ~1)
        val normal_p0 = test pos0 (0, 0, 0, 0)
        val normal_n0 = test neg0 (0, 0, 0, 0)
      in () end
  fun toInt_normal_0002 () =
      let
        val normal_maxInt = test maxInt_r (maxInt, maxInt, maxInt, maxInt)
        val normal_minInt = test minInt_r (minInt, minInt, minInt, minInt)
      in () end
  end (* local *)
  local
    fun test mode arg expected = assertEqualInt expected (R.toInt mode arg)
    fun testFail mode arg =
        (R.toInt mode arg; fail "Overflow expected")
        handle General.Overflow => ()
  in
  fun toInt_normal_1001 () =
      let
        (* all modes fail. *)
        val maxIntPlus1_r = maxInt_r + 1.0
        val minIntMinus1_r = minInt_r - 1.0

        val toInt_pinf_NEAREST = testFail IR.TO_NEAREST maxIntPlus1_r
        val toInt_pinf_NEGINF = testFail IR.TO_NEGINF maxIntPlus1_r
        val toInt_pinf_POSINF = testFail IR.TO_POSINF maxIntPlus1_r
        val toInt_pinf_ZERO = testFail IR.TO_ZERO maxIntPlus1_r

        val toInt_ninf_NEAREST = testFail IR.TO_NEAREST minIntMinus1_r
        val toInt_ninf_NEGINF = testFail IR.TO_NEGINF minIntMinus1_r
        val toInt_ninf_POSINF = testFail IR.TO_POSINF minIntMinus1_r
        val toInt_ninf_ZERO = testFail IR.TO_ZERO minIntMinus1_r
      in () end
  fun toInt_normal_1002 () =
      let
        (* TO_NEAREST succeeds. *)
        val maxIntPlus04_r = maxInt_r + 0.4
        val minIntMinus04_r = minInt_r - 0.4

        val toInt_pinf_NEAREST = test IR.TO_NEAREST maxIntPlus04_r maxInt
        val toInt_pinf_NEGINF = test IR.TO_NEGINF maxIntPlus04_r maxInt
        val toInt_pinf_POSINF = testFail IR.TO_POSINF maxIntPlus04_r
        val toInt_pinf_ZERO = test IR.TO_ZERO maxIntPlus04_r maxInt

        val toInt_ninf_NEAREST = test IR.TO_NEAREST minIntMinus04_r minInt
        val toInt_ninf_NEGINF = testFail IR.TO_NEGINF minIntMinus04_r
        val toInt_ninf_POSINF = test IR.TO_POSINF minIntMinus04_r minInt
        val toInt_ninf_ZERO = test IR.TO_ZERO minIntMinus04_r minInt
      in () end
  fun toInt_normal_1003 () =
      let
        (* TO_NEAREST fails *)
        val maxIntPlus06_r = maxInt_r + 0.6
        val minIntMinus06_r = minInt_r - 0.6

        val toInt_pinf_NEAREST = testFail IR.TO_NEAREST maxIntPlus06_r
        val toInt_pinf_NEGINF = test IR.TO_NEGINF maxIntPlus06_r maxInt
        val toInt_pinf_POSINF = testFail IR.TO_POSINF maxIntPlus06_r
        val toInt_pinf_ZERO = test IR.TO_ZERO maxIntPlus06_r maxInt

        val toInt_ninf_NEAREST = testFail IR.TO_NEAREST minIntMinus06_r
        val toInt_ninf_NEGINF = testFail IR.TO_NEGINF minIntMinus06_r
        val toInt_ninf_POSINF = test IR.TO_POSINF minIntMinus06_r minInt
        val toInt_ninf_ZERO = test IR.TO_ZERO minIntMinus06_r minInt
      in () end
  end (* local *)

  local
    fun test mode arg =
        (R.toInt mode arg; fail "Overflow expected")
        handle General.Overflow => ()
  in
  fun toInt_inf_0001 () =
      let
        val toInt_pinf_NEAREST = test IR.TO_NEAREST posInf
        val toInt_pinf_NEGINF = test IR.TO_NEGINF posInf
        val toInt_pinf_POSINF = test IR.TO_POSINF posInf
        val toInt_pinf_ZERO = test IR.TO_ZERO posInf

        val toInt_ninf_NEAREST = test IR.TO_NEAREST negInf
        val toInt_ninf_NEGINF = test IR.TO_NEGINF negInf
        val toInt_ninf_POSINF = test IR.TO_POSINF negInf
        val toInt_ninf_ZERO = test IR.TO_ZERO negInf
      in () end
  end (* local *)

  local
    fun test mode arg =
        (R.toInt mode arg; fail "Domain expected") handle General.Domain => ()
  in
  fun toInt_nan_0001 () =
      let
        val toInt_pnan_NEAREST = test IR.TO_NEAREST posNan
        val toInt_pnan_NEGINF = test IR.TO_NEGINF posNan
        val toInt_pnan_POSINF = test IR.TO_POSINF posNan
        val toInt_pnan_ZERO = test IR.TO_ZERO posNan

        val toInt_nnan_NEAREST = test IR.TO_NEAREST negNan
        val toInt_nnan_NEGINF = test IR.TO_NEGINF negNan
        val toInt_nnan_POSINF = test IR.TO_POSINF negNan
        val toInt_nnan_ZERO = test IR.TO_ZERO negNan
      in () end
  end (* local *)

  (**********)

  local
    fun test arg expected =
        assertEqual4LargeInt
            expected
            (
              R.toLargeInt IR.TO_NEAREST arg,
              R.toLargeInt IR.TO_NEGINF arg,
              R.toLargeInt IR.TO_POSINF arg,
              R.toLargeInt IR.TO_ZERO arg
            )
  in
  fun toLargeInt_normal_0001 () =
      let
        val normal_p14 = test 1.4 (1, 1, 2, 1)
        val normal_p15 = test 1.5 (2, 1, 2, 1)
        val normal_n14 = test ~1.4 (~1, ~2, ~1, ~1)
        val normal_n15 = test ~1.5 (~2, ~2, ~1, ~1)
        val normal_p0 = test pos0 (0, 0, 0, 0)
        val normal_n0 = test neg0 (0, 0, 0, 0)
      in () end
  fun toLargeInt_normal_0002 () =
      (* test Int.maxInt. *)
      let
        val maxInt = maxInt_L
        val minInt = minInt_L
        val normal_maxInt = test maxInt_r (maxInt, maxInt, maxInt, maxInt)
        val normal_minInt = test minInt_r (minInt, minInt, minInt, minInt)
      in () end
  fun toLargeInt_normal_0003 () =
      (* test greater than Int.maxInt and less than Int.minInt *)
      if (NONE = I.precision)
         orelse
         (isSome LI.precision andalso valOf LI.precision <= valOf I.precision)
      then () (* This test is unnecessary. *)
      else
        let
          val maxIntP1_r = maxInt_r + 1.0
          val maxIntP1 = maxInt_L + 1
          val minIntM1_r = minInt_r - 1.0
          val minIntM1 = minInt_L - 1
          val normal_maxInt =
              test maxIntP1_r (maxIntP1, maxIntP1, maxIntP1, maxIntP1)
          val normal_minInt =
              test minIntM1_r (minIntM1, minIntM1, minIntM1, minIntM1)
        in () end
  end (* local *)

  local
    fun test mode arg =
        (R.toLargeInt mode arg; fail "Overflow expected")
        handle General.Overflow => ()
  in
  fun toLargeInt_inf_0001 () =
      let
        val toLargeInt_pinf_NEAREST = test IR.TO_NEAREST posInf
        val toLargeInt_pinf_NEGINF = test IR.TO_NEGINF posInf
        val toLargeInt_pinf_POSINF = test IR.TO_POSINF posInf
        val toLargeInt_pinf_ZERO = test IR.TO_ZERO posInf

        val toLargeInt_ninf_NEAREST = test IR.TO_NEAREST negInf
        val toLargeInt_ninf_NEGINF = test IR.TO_NEGINF negInf
        val toLargeInt_ninf_POSINF = test IR.TO_POSINF negInf
        val toLargeInt_ninf_ZERO = test IR.TO_ZERO negInf
      in () end
  end (* local *)

  local
    fun test mode arg =
        (R.toLargeInt mode arg; fail "Domain expected")
        handle General.Domain => ()
  in
  fun toLargeInt_nan_0001 () =
      let
        val toLargeInt_pnan_NEAREST = test IR.TO_NEAREST posNan
        val toLargeInt_pnan_NEGINF = test IR.TO_NEGINF posNan
        val toLargeInt_pnan_POSINF = test IR.TO_POSINF posNan
        val toLargeInt_pnan_ZERO = test IR.TO_ZERO posNan

        val toLargeInt_nnan_NEAREST = test IR.TO_NEAREST negNan
        val toLargeInt_nnan_NEGINF = test IR.TO_NEGINF negNan
        val toLargeInt_nnan_POSINF = test IR.TO_POSINF negNan
        val toLargeInt_nnan_ZERO = test IR.TO_ZERO negNan
      in () end
  end (* local *)

  (**********)

  fun fromInt0001 () =
      let
        val fromInt_p = R.fromInt 123
        val _ = assertEqualReal 123.0 fromInt_p

        val fromInt_n = R.fromInt ~123
        val _ = assertEqualReal ~123.0 fromInt_n

        val fromInt_0 = R.fromInt 0
        val _ = assertEqualReal pos0 fromInt_0
      in () end

  (**********)

  fun fromLargeInt0001 () =
      let
        val fromLargeInt_p = R.fromLargeInt 123
        val _ = assertEqualReal 123.0 fromLargeInt_p

        val fromLargeInt_n = R.fromLargeInt ~123
        val _ = assertEqualReal ~123.0 fromLargeInt_n

        val fromLargeInt_0 = R.fromLargeInt 0
        val _ = assertEqualReal pos0 fromLargeInt_0
      in () end

  (**********)

  local
    val largePosNan = LR.copySign(LR.posInf * 0.0, 1.0)
    val largeNegNan = LR.copySign(LR.negInf * 0.0, ~1.0)
  in

  local fun test arg expected = ALR.assertEqualReal expected (R.toLarge arg)
  in
  fun toLarge0001 () =
      let
        val toLarge_p = test 1.23 1.23
        val toLarge_n = test ~1.23 ~1.23
        val toLarge_p0 = test pos0 0.0
        val toLarge_n0 = test pos0 ~0.0
        val toLarge_pinf = test posInf LR.posInf
        val toLarge_ninf = test negInf LR.negInf
        val toLarge_pnan = test posNan largePosNan
        val toLarge_nnan = test negNan largeNegNan
      in () end
  end (* inner local *)

  local
    fun test arg expected =
        assertEqual4Real
            expected
            (
              R.fromLarge IR.TO_NEAREST arg,
              R.fromLarge IR.TO_NEGINF arg,
              R.fromLarge IR.TO_POSINF arg,
              R.fromLarge IR.TO_ZERO arg
            )
  in
  fun fromLarge0001 () =
      let
        val normal_p14 = test 1.4 (1.4, 1.4, 1.4, 1.4)
        val normal_p15 = test 1.5 (1.5, 1.5, 1.5, 1.5)
        val normal_n14 = test ~1.4 (~1.4, ~1.4, ~1.4, ~1.4)
        val normal_n15 = test ~1.5 (~1.5, ~1.5, ~1.5, ~1.5)
        val normal_p0 = test 0.0 (pos0, pos0, pos0, pos0)
        val normal_n0 = test ~0.0 (neg0, neg0, neg0, neg0)
        val normal_pinf = test LR.posInf (posInf, posInf, posInf, posInf)
        val normal_ninf = test LR.negInf (negInf, negInf, negInf, negInf)
        val normal_pnan = test largePosNan (posNan, posNan, posNan, posNan)
        val normal_nnan = test largeNegNan (negNan, negNan, negNan, negNan)
      in () end
  end (* inner local *)

  end (* outer local *)

  (**********)

  (* To avoid error of float numbers which fluctuate test results,
   * we use float numbers which can be represented as the sum of powers
   * of 2 exactly.
   * 0.1875 = 0.125 + 0.0625 = 2^(-3) + 2^(-4)
   *)
  local
    fun test spec arg expected = assertEqualString expected (R.fmt spec arg)
    datatype realfmt = datatype StringCvt.realfmt
  in
  fun fmt_SCI_normal_0001 () =
      let
        val fmt_SCI_1875_N_1 = test (SCI NONE) 18.75 "1.875000E1"
        val fmt_SCI_1875_0_1 = test (SCI (SOME 0)) 18.75 "1E1"
        val fmt_SCI_1875_1_1 = test (SCI (SOME 1)) 18.75 "1.8E1"
        val fmt_SCI_1875_2_1 = test (SCI (SOME 2)) 18.75 "1.87E1"
        val fmt_SCI_1875_3_1 = test (SCI (SOME 3)) 18.75 "1.875E1"
        val fmt_SCI_1875_4_1 = test (SCI (SOME 4)) 18.75 "1.8750E1"

        val fmt_SCI_1875_N_0 = test (SCI NONE) 1.875 "1.875000E0"
        val fmt_SCI_1875_N_n1 = test (SCI NONE) 0.1875 "1.875000E~1"

        val fmt_SCI_n1875_N_1 = test (SCI NONE) ~18.75 "~1.875000E1"
      in () end
  (* check exponential. The real is just on power of 10. *)
  fun fmt_SCI_normal_0010 () =
      let
        val fmt_SCI_100_N_1 = test (SCI NONE) 10.0 "1.000000E1"
        val fmt_SCI_100_0_1 = test (SCI (SOME 0)) 10.0 "1E1"
        val fmt_SCI_100_1_1 = test (SCI (SOME 1)) 10.0 "1.0E1"
        val fmt_SCI_100_2_1 = test (SCI (SOME 2)) 10.0 "1.00E1"
        val fmt_SCI_100_3_1 = test (SCI (SOME 3)) 10.0 "1.000E1"
      in () end
  (* check rounding. The most significant digit is under 5 *)
  fun fmt_SCI_normal_0011 () =
      let
        val fmt_SCI_400_N_1 = test (SCI NONE) 40.0 "4.000000E1"
        val fmt_SCI_400_0_1 = test (SCI (SOME 0)) 40.0 "4E1"
        val fmt_SCI_400_1_1 = test (SCI (SOME 1)) 40.0 "4.0E1"
        val fmt_SCI_400_2_1 = test (SCI (SOME 2)) 40.0 "4.00E1"
        val fmt_SCI_400_3_1 = test (SCI (SOME 3)) 40.0 "4.000E1"
      in () end
  (* check rounding. The most significant digit is over 5 *)
  fun fmt_SCI_normal_0012 () =
      let
        val fmt_SCI_600_N_1 = test (SCI NONE) 60.0 "6.000000E1"
        val fmt_SCI_600_0_1 = test (SCI (SOME 0)) 60.0 "6E1"
        val fmt_SCI_600_1_1 = test (SCI (SOME 1)) 60.0 "6.0E1"
        val fmt_SCI_600_2_1 = test (SCI (SOME 2)) 60.0 "6.00E1"
        val fmt_SCI_600_3_1 = test (SCI (SOME 3)) 60.0 "6.000E1"
      in () end
  (* check sign *)
  fun fmt_SCI_normal_0013 () =
      let
        val fmt_SCI_n100_N_1 = test (SCI NONE) ~10.0 "~1.000000E1"
        val fmt_SCI_n100_0_1 = test (SCI (SOME 0)) ~10.0 "~1E1"
        val fmt_SCI_n100_1_1 = test (SCI (SOME 1)) ~10.0 "~1.0E1"
        val fmt_SCI_n100_2_1 = test (SCI (SOME 2)) ~10.0 "~1.00E1"
        val fmt_SCI_n100_3_1 = test (SCI (SOME 3)) ~10.0 "~1.000E1"
      in () end
  (* check exponential. The real is just on power of 10. *)
  fun fmt_SCI_normal_0020 () =
      let
        val fmt_SCI_0001_N_n3 = test (SCI NONE) 0.001 "1.000000E~3"
        val fmt_SCI_0001_0_n3 = test (SCI (SOME 0)) 0.001 "1E~3"
        val fmt_SCI_0001_1_n3 = test (SCI (SOME 1)) 0.001 "1.0E~3"
        val fmt_SCI_0001_2_n3 = test (SCI (SOME 2)) 0.001 "1.00E~3"
        val fmt_SCI_0001_3_n3 = test (SCI (SOME 3)) 0.001 "1.000E~3"
        val fmt_SCI_0001_4_n3 = test (SCI (SOME 4)) 0.001 "1.0000E~3"
      in () end
  (* check rounding. The most significant digit is under 5 *)
  fun fmt_SCI_normal_0021 () =
      let
        val fmt_SCI_0004_N_n3 = test (SCI NONE) 0.004 "4.000000E~3"
        val fmt_SCI_0004_0_n3 = test (SCI (SOME 0)) 0.004 "4E~3"
        val fmt_SCI_0004_1_n3 = test (SCI (SOME 1)) 0.004 "4.0E~3"
        val fmt_SCI_0004_2_n3 = test (SCI (SOME 2)) 0.004 "4.00E~3"
        val fmt_SCI_0004_3_n3 = test (SCI (SOME 3)) 0.004 "4.000E~3"
        val fmt_SCI_0004_4_n3 = test (SCI (SOME 4)) 0.004 "4.0000E~3"
      in () end
  (* check rounding. The most significant digit is over 5 *)
  fun fmt_SCI_normal_0022 () =
      let
        val fmt_SCI_0006_N_n3 = test (SCI NONE) 0.006 "6.000000E~3"
        val fmt_SCI_0006_0_n3 = test (SCI (SOME 0)) 0.006 "6E~3"
        val fmt_SCI_0006_1_n3 = test (SCI (SOME 1)) 0.006 "6.0E~3"
        val fmt_SCI_0006_2_n3 = test (SCI (SOME 2)) 0.006 "6.00E~3"
        val fmt_SCI_0006_3_n3 = test (SCI (SOME 3)) 0.006 "6.000E~3"
        val fmt_SCI_0006_4_n3 = test (SCI (SOME 4)) 0.006 "6.0000E~3"
      in () end
  (* check sign *)
  fun fmt_SCI_normal_0023 () =
      let
        val fmt_SCI_n0001_N_n3 = test (SCI NONE) ~0.001 "~1.000000E~3"
        val fmt_SCI_n0001_0_n3 = test (SCI (SOME 0)) ~0.001 "~1E~3"
        val fmt_SCI_n0001_1_n3 = test (SCI (SOME 1)) ~0.001 "~1.0E~3"
        val fmt_SCI_n0001_2_n3 = test (SCI (SOME 2)) ~0.001 "~1.00E~3"
        val fmt_SCI_n0001_3_n3 = test (SCI (SOME 3)) ~0.001 "~1.000E~3"
        val fmt_SCI_n0001_4_n3 = test (SCI (SOME 4)) ~0.001 "~1.0000E~3"
      in () end
  fun fmt_SCI_abnormal () =
      let
        val fmt_SCI_p0_N = test (SCI NONE) pos0 "0.000000E0"
        val fmt_SCI_p0_0 = test (SCI (SOME 0)) pos0 "0E0"
        val fmt_SCI_p0_1 = test (SCI (SOME 1)) pos0 "0.0E0"
        val fmt_SCI_n0_N = test (SCI NONE) neg0 "~0.000000E0"
        val fmt_SCI_n0_0 = test (SCI (SOME 0)) neg0 "~0E0"
        val fmt_SCI_n0_1 = test (SCI (SOME 1)) neg0 "~0.0E0"
        val fmt_SCI_pinf_N = test (SCI NONE) posInf "inf"
        val fmt_SCI_ninf_N = test (SCI NONE) negInf "~inf"
        (* sign of nan is ignored. *)
        val fmt_SCI_pnan_N = test (SCI NONE) posNan "nan"
        val fmt_SCI_nnan_N = test (SCI NONE) negNan "nan"
      in () end

  fun fmt_FIX_normal_0001 () =
      let
        val fmt_FIX_1875_N_1 = test (FIX NONE) 18.75 "18.750000"
        val fmt_FIX_1875_0_1 = test (FIX (SOME 0)) 18.75 "18"
        val fmt_FIX_1875_1_1 = test (FIX (SOME 1)) 18.75 "18.7"
        val fmt_FIX_1875_2_1 = test (FIX (SOME 2)) 18.75 "18.75"
        val fmt_FIX_1875_3_1 = test (FIX (SOME 3)) 18.75 "18.750"
        val fmt_FIX_1875_4_1 = test (FIX (SOME 4)) 18.75 "18.7500"

        val fmt_FIX_1875_N_0 = test (FIX NONE) 1.875 "1.875000"
        val fmt_FIX_1875_N_n1 = test (FIX NONE) 0.1875 "0.187500"

        val fmt_FIX_n1875_N_1 = test (FIX NONE) ~18.75 "~18.750000"
      in () end
  (* check exponential. The real is just on power of 10. *)
  fun fmt_FIX_normal_0010 () =
      let
        val fmt_FIX_100_N_1 = test (FIX NONE) 10.0 "10.000000"
        val fmt_FIX_100_0_1 = test (FIX (SOME 0)) 10.0 "10"
        val fmt_FIX_100_1_1 = test (FIX (SOME 1)) 10.0 "10.0"
        val fmt_FIX_100_2_1 = test (FIX (SOME 2)) 10.0 "10.00"
        val fmt_FIX_100_3_1 = test (FIX (SOME 3)) 10.0 "10.000"
      in () end
  (* check rounding. The most significant digit is under 5 *)
  fun fmt_FIX_normal_0011 () =
      let
        val fmt_FIX_400_N_1 = test (FIX NONE) 40.0 "40.000000"
        val fmt_FIX_400_0_1 = test (FIX (SOME 0)) 40.0 "40"
        val fmt_FIX_400_1_1 = test (FIX (SOME 1)) 40.0 "40.0"
        val fmt_FIX_400_2_1 = test (FIX (SOME 2)) 40.0 "40.00"
        val fmt_FIX_400_3_1 = test (FIX (SOME 3)) 40.0 "40.000"
      in () end
  (* check rounding. The most significant digit is over 5 *)
  fun fmt_FIX_normal_0012 () =
      let
        val fmt_FIX_600_N_1 = test (FIX NONE) 60.0 "60.000000"
        val fmt_FIX_600_0_1 = test (FIX (SOME 0)) 60.0 "60"
        val fmt_FIX_600_1_1 = test (FIX (SOME 1)) 60.0 "60.0"
        val fmt_FIX_600_2_1 = test (FIX (SOME 2)) 60.0 "60.00"
        val fmt_FIX_600_3_1 = test (FIX (SOME 3)) 60.0 "60.000"
      in () end
  (* check sign. *)
  fun fmt_FIX_normal_0013 () =
      let
        val fmt_FIX_n100_N_1 = test (FIX NONE) ~10.0 "~10.000000"
        val fmt_FIX_n100_0_1 = test (FIX (SOME 0)) ~10.0 "~10"
        val fmt_FIX_n100_1_1 = test (FIX (SOME 1)) ~10.0 "~10.0"
        val fmt_FIX_n100_2_1 = test (FIX (SOME 2)) ~10.0 "~10.00"
        val fmt_FIX_n100_3_1 = test (FIX (SOME 3)) ~10.0 "~10.000"
      in () end
  (* check exponential. The real is just on power of 10. *)
  fun fmt_FIX_normal_0020 () =
      let
        val fmt_FIX_0001_N_n3 = test (FIX NONE) 0.001 "0.001000"
        val fmt_FIX_0001_0_n3 = test (FIX (SOME 0)) 0.001 "0"
        val fmt_FIX_0001_1_n3 = test (FIX (SOME 1)) 0.001 "0.0"
        val fmt_FIX_0001_2_n3 = test (FIX (SOME 2)) 0.001 "0.00"
        val fmt_FIX_0001_3_n3 = test (FIX (SOME 3)) 0.001 "0.001"
        val fmt_FIX_0001_4_n3 = test (FIX (SOME 4)) 0.001 "0.0010"
      in () end
  (* check exponential. The most significant digit is under 5 *)
  fun fmt_FIX_normal_0021 () =
      let
        val fmt_FIX_0004_N_n3 = test (FIX NONE) 0.004 "0.004000"
        val fmt_FIX_0004_0_n3 = test (FIX (SOME 0)) 0.004 "0"
        val fmt_FIX_0004_1_n3 = test (FIX (SOME 1)) 0.004 "0.0"
        val fmt_FIX_0004_2_n3 = test (FIX (SOME 2)) 0.004 "0.00"
        val fmt_FIX_0004_3_n3 = test (FIX (SOME 3)) 0.004 "0.004"
        val fmt_FIX_0004_4_n3 = test (FIX (SOME 4)) 0.004 "0.0040"
      in () end
  (* check exponential. The most significant digit is over 5 *)
  fun fmt_FIX_normal_0022 () =
      let
        val fmt_FIX_0006_N_n3 = test (FIX NONE) 0.006 "0.006000"
        val fmt_FIX_0006_0_n3 = test (FIX (SOME 0)) 0.006 "0"
        val fmt_FIX_0006_1_n3 = test (FIX (SOME 1)) 0.006 "0.0"
        val fmt_FIX_0006_2_n3 = test (FIX (SOME 2)) 0.006 "0.00"
        val fmt_FIX_0006_3_n3 = test (FIX (SOME 3)) 0.006 "0.006"
        val fmt_FIX_0006_4_n3 = test (FIX (SOME 4)) 0.006 "0.0060"
      in () end
  (* check sign. *)
  fun fmt_FIX_normal_0023 () =
      let
        val fmt_FIX_n0001_N_n3 = test (FIX NONE) ~0.001 "~0.001000"
        val fmt_FIX_n0001_0_n3 = test (FIX (SOME 0)) ~0.001 "~0"
        val fmt_FIX_n0001_1_n3 = test (FIX (SOME 1)) ~0.001 "~0.0"
        val fmt_FIX_n0001_2_n3 = test (FIX (SOME 2)) ~0.001 "~0.00"
        val fmt_FIX_n0001_3_n3 = test (FIX (SOME 3)) ~0.001 "~0.001"
        val fmt_FIX_n0001_4_n3 = test (FIX (SOME 4)) ~0.001 "~0.0010"
      in () end
  fun fmt_FIX_abnormal () =
      let
        val fmt_FIX_p0_N = test (FIX NONE) pos0 "0.000000"
        val fmt_FIX_p0_0 = test (FIX (SOME 0)) pos0 "0"
        val fmt_FIX_p0_1 = test (FIX (SOME 1)) pos0 "0.0"
        val fmt_FIX_n0_N = test (FIX NONE) neg0 "~0.000000"
        val fmt_FIX_n0_0 = test (FIX (SOME 0)) neg0 "~0"
        val fmt_FIX_n0_1 = test (FIX (SOME 1)) neg0 "~0.0"
        val fmt_FIX_pinf_N = test (FIX NONE) posInf "inf"
        val fmt_FIX_ninf_N = test (FIX NONE) negInf "~inf"
        val fmt_FIX_pnan_N = test (FIX NONE) posNan "nan"
        val fmt_FIX_nnan_N = test (FIX NONE) negNan "nan"
      in () end

  fun fmt_GEN_normal_NONE_posExp () =
      let
        (* NONE indicates SOME(12) *)

        (*
         * FIX: 1234567890100000
         * SCI: 1.2345678901E15
         * Because trailing 0 is truncated, only 11 digits is printed in SCI
         * format.
         *)
        val fmt_GEN_p_N_11 =
            test (GEN NONE) 1234567890100000.0 "1.2345678901E15" (* SCI *)
        (*
         * FIX: 1234567890120000
         * SCI: 1.23456789012E15
         * Both are the same length. FIX should be selected.
         *)
        val fmt_GEN_p_N_12 =
            test (GEN NONE) 1234567890120000.0 "1234567890120000" (* FIX *)
        val fmt_GEN_p_N_13 =
            test (GEN NONE) 1234567890123000.0 "1234567890120000" (* FIX *)
      in () end
  fun fmt_GEN_normal_NONE_negExp () =
      let
        (* NONE indicates SOME(12) *)

        (*
         * FIX: 0.0012345678901
         * SCI: 1.2345678901E~3
         * Both are the same length. FIX should be selected.
         *)
        val fmt_GEN_p_N_n3_11 =
            test (GEN NONE) 0.0012345678901 "0.0012345678901" (* FIX *)
        (*
         * FIX: 0.00012345678901
         * SCI: 1.2345678901E~4
         *)
        val fmt_GEN_p_N_n4_11 =
            test (GEN NONE) 0.00012345678901 "1.2345678901E~4" (* SCI *)
        (*
         * FIX: 0.000123456789012
         * SCI: 1.23456789012E~4
         *)
        val fmt_GEN_p_N__n4_12 =
            test (GEN NONE) 0.000123456789012 "1.23456789012E~4" (* SCI *)
        val fmt_GEN_p_N__n4_13 =
            test (GEN NONE) 0.0001234567890123 "1.23456789012E~4" (* SCI *)
      in () end
  fun fmt_GEN_normal_SOME_posExp () =
      let
        (* shorter format of SCI or FIX should be selected. *)

        (* GEN (SOME(0)) is error *)

        (* SCI: 1E4
         * FIX: 10000 *)
        val fmt_GEN_p_1_4 = test (GEN (SOME 1)) 13500.13 "1E4" (* SCI *)
        (* SCI: 1.3E4
         * FIX: 13000 *)
        val fmt_GEN_p_2_4 = test (GEN (SOME 2)) 13500.13 "13000" (* FIX *)
        (* SCI: 1.35E4
         * FIX: 13500 *)
        val fmt_GEN_p_3_4 = test (GEN (SOME 3)) 13500.13 "13500" (* FIX *)
      in () end
  fun fmt_GEN_normal_SOME_negExp () =
      let
        (* negative Exp *)

        (* SCI: 1.23E~2
         * FIX: 0.0123 *)
        val fmt_GEN_n_n2_3 = test (GEN (SOME 3)) 0.01234 "0.0123"
        (* SCI: 1.23E~3
         * FIX: 0.00123 *)
        val fmt_GEN_p_n3_3 = test (GEN (SOME 3)) 0.001234 "0.00123"
        (* SCI: 1.23E~4
         * FIX: 0.000123 *)
        val fmt_GEN_p_n4_3 = test (GEN (SOME 3)) 0.0001234 "1.23E~4"
      in () end
  fun fmt_GEN_abnormal () =
      let
        val fmt_GEN_p0_N = test (GEN NONE) pos0 "0"
        val fmt_GEN_p0_1 = test (GEN (SOME 1)) pos0 "0"
        val fmt_GEN_n0_N = test (GEN NONE) neg0 "~0"
        val fmt_GEN_n0_1 = test (GEN (SOME 1)) neg0 "~0"
        val fmt_GEN_pinf_N = test (GEN NONE) posInf "inf"
        val fmt_GEN_ninf_N = test (GEN NONE) negInf "~inf"
        val fmt_GEN_pnan_N = test (GEN NONE) posNan "nan"
        val fmt_GEN_nnan_N = test (GEN NONE) negNan "nan"
      in () end

  fun fmt_error () =
      let
        val fmt_SCI =
            (R.fmt (SCI (SOME ~1)); fail "frm SCI(~1) should raise Size.")
            handle General.Size => ()
        val fmt_FIX =
            (R.fmt (FIX (SOME ~1)); fail "frm FIX(~1) should raise Size.")
            handle General.Size => ()
        val fmt_GEN =
            (R.fmt (GEN (SOME 0)); fail "frm GEN(0) should raise Size.")
            handle General.Size => ()
      in () end

  end (* local *)

  (**********)

  local fun test arg expected = assertEqualString expected (R.toString arg)
  in
  fun toString001 () =
      let
        (* Real.toString is equivalent to Real.fmt (StringCvt.GEN NONE) *)
        val toString_n2 = test 0.01234567890123 "0.0123456789012"
        val toString_n3 = test 0.001234567890123 "0.00123456789012"
        val toString_n4 = test 0.0001234567890123 "1.23456789012E~4"

        val toString_14 = test 123456789012300.0 "123456789012000"
        val toString_15 = test 1234567890123000.0 "1234567890120000"
        val toString_16 = test 12345678901230000.0 "1.23456789012E16"
      in () end
  end (* local *)

  (**********)

  local
    val scan =
        (Option.map (fn(r, ss) => (r, Substring.string ss))
         o Real.scan Substring.getc
         o Substring.full)
    fun test arg expected = assertEqualRSOption expected (scan arg)
  in
  (* The valid format of Real.scan for normal floats is:
   * [+~-]?([0-9]+.[0-9]+? | .[0-9]+)(e | E)[+~-]?[0-9]+?
   *
   * Test number consists of 5 fields:
   *   {sign}_{int}_{frac}_{exp_sign}_{exp}
   * Each field has following values:
   *   sign: N,p,t,m
   *   int: N,{n}
   *   frac: N,{n}
   *   exp_sign: N,p,t,m
   *   exp: N,{n}
   * N indicates nothing specified.
   * {n} indicates any integer.
   *)
  (* safe case for normal real. *)
  fun scan_normal_0001 () =
      let
        (* test case for numbers with whole part *)
        val normal_N_123_N_N_N = test "123" (SOME(123.0, ""))
        val normal_N_123_456_N_N = test "123.456" (SOME(123.456, ""))
        val normal_N_123_456_N_1 = test "123.456E1" (SOME(1234.56, ""))

        val normal_p_123_N_N_N = test "+123" (SOME(123.0, ""))
        val normal_t_123_N_N_N = test "~123" (SOME(~123.0, ""))
        val normal_m_123_N_N_N = test "-123" (SOME(~123.0, ""))
        val normal_m_123_456_N_1 = test "-123.456E1" (SOME(~1234.56, ""))
        val normal_m_123_456_m_1 = test "-123.456E-1" (SOME(~12.3456, ""))
      in () end
  fun scan_normal_0002 () =
      let
        (* test case for numbers with no whole part *)
        val normal_N_N_123_N_1 = test ".123E1" (SOME(1.23, ""))
        val normal_N_N_123_N_10 = test ".123E10" (SOME(1230000000.0, ""))
        val normal_N_N_123_p_1 = test ".123E+1" (SOME(1.23, ""))
        val normal_N_N_123_t_1 = test ".123E~1" (SOME(0.0123, ""))
        val normal_N_N_123_m_1 = test ".123E-1" (SOME(0.0123, ""))
        val normal_N_N_123_m_10 = test ".123E-10" (SOME(0.0000000000123, ""))
      in () end
  fun scan_normal_0003 () =
      let
        (* test case for zero. *)
        val normal_N_N_0_N_N = test ".0E1" (SOME(0.0, ""))
        val normal_N_0_N_N_N = test "0E1" (SOME(0.0, ""))
        val normal_N_0_0_N_N = test "0.0E1" (SOME(0.0, ""))
        val normal_p_0_0_N_N = test "0.0E1" (SOME(pos0, ""))
        val normal_t_0_0_N_N = test "~0.0E1" (SOME(neg0, ""))
        val normal_m_0_0_N_N = test "-0.0E1" (SOME(neg0, ""))
      in () end
  fun scan_normal_0010 () =
      let
        (* test case for initial whitespaces and trailer *)
        val normal_initws = test " \n\r\t\v\f123.456" (SOME(123.456, ""))
        val normal_trail_1 = test "123.456ABC" (SOME(123.456, "ABC"))
        val normal_trail_2 = test "123.456.123" (SOME(123.456, ".123"))
      in () end
  fun scan_normal_0011 () =
      let
        (* test case for case insensitive *)
        val normal_smallE = test "123.456e1" (SOME(1234.56, ""))
        val normal_largeE = test "123.456E1" (SOME(1234.56, ""))
      in () end
  fun scan_normal_0012 () =
      let
        (* test case for extremes. *)
        val normal_error_Ebig = test "1E1000" (SOME(posInf, ""))
      in () end
  fun scan_normal_1001 () =
      let
        (* test cases for bugs? in the format specified in Basis spec. *)
        (* With whole part and 'E', but no exponential part. *)
        val normal_error_E1 = test "1EA" (SOME(1.0, "A"))
        (* With 'E' and exponential, but no whole part. *)
        val normal_error_E2 = test "E1" NONE
        (* Only 'E' *)
        val normal_error_E3 = test "E" NONE
        (* With decimal point, but no fractional part. *)
        val normal_error_dot = test "1..1" (SOME(1.0, ".1"))
      in () end

  (* The valid format of Real.scan for abnormal floats is:
   * [+~-]?(inf | infinity | nan)
   *)
  fun scan_abnormal_0001 () =
      let
        val abnormal_N_inf = test "inf" (SOME(posInf, ""))
        val abnormal_N_infinity = test "infinity" (SOME(posInf, ""))
        val abnormal_N_nan = test "nan" (SOME(posNan, ""))

        val abnormal_p_inf = test "+inf" (SOME(posInf, ""))
        val abnormal_p_infinity = test "+infinity" (SOME(posInf, ""))
        val abnormal_p_nan = test "+nan" (SOME(posNan, ""))

        val abnormal_t_inf = test "~inf" (SOME(negInf, ""))
        val abnormal_t_infinity = test "~infinity" (SOME(negInf, ""))
        val abnormal_t_nan = test "~nan" (SOME(negNan, ""))
      in () end
  fun scan_abnormal_0002 () =
      let
        (* test case for case insensitive *)
        val abnormal_INF = test "INF" (SOME(posInf, ""))
        val abnormal_INFINITY = test "INFINITY" (SOME(posInf, ""))
        val abnormal_NAN = test "NAN" (SOME(posNan, ""))
      in () end
  fun scan_abnormal_0010 () =
      let
        (* test case for initial whitespace and trailer *)
        val abnormal_initws_inf = test " \n\r\t\v\finf" (SOME(posInf, ""))
        val abnormal_initws_infinity = test " \n\r\t\v\finfinity" (SOME(posInf, ""))
        val abnormal_initws_nan = test " \n\r\t\v\fnan" (SOME(posNan, ""))

        val abnormal_trail_inf_1 = test "infABC" (SOME(posInf, "ABC"))
        val abnormal_trail_inf_2 = test "infinit" (SOME(posInf, "init"))
        val abnormal_trail_infinity = test "infinityABC" (SOME(posInf, "ABC"))
        val abnormal_trail_nan = test "nanABC" (SOME(posNan, "ABC"))
      in () end
  end (* local *)

  (**********)

  fun fromString0001 () =
      let
        val fromString_1 = R.fromString "123.456E10"
        val _ = assertEqualRealOption (SOME(1234560000000.0))

        val fromString_2 = R.fromString "ABC"
        val _ = assertEqualRealOption NONE
      in () end

  (**********)

  local
    fun makeDec (class, sign, digits, exp) =
        {class = class, sign = sign, digits = digits, exp = exp}
        : IR.decimal_approx
  in
  local
    fun test arg expected =
        assertEqualDecimalApprox (makeDec expected) (R.toDecimal arg)
  in
  fun toDecimal_normal_0001 () =
      let
        val normal_p_p = test 12.5 (IR.NORMAL, false, [1, 2, 5], 2)
        val normal_p_0 = test 0.125 (IR.NORMAL, false, [1, 2, 5], 0)
        val normal_p_n = test 0.015625 (IR.NORMAL, false, [1, 5, 6, 2, 5], ~1)

        val normal_n_p = test ~12.5 (IR.NORMAL, true, [1, 2, 5], 2)
        val normal_n_0 = test ~0.125 (IR.NORMAL, true, [1, 2, 5], 0)
        val normal_n_n = test ~0.015625 (IR.NORMAL, true, [1, 5, 6, 2, 5], ~1)
      in () end
  fun toDecimal_abnormal_0001 () =
      let
        val normal_p0 = test pos0 (IR.ZERO, false, [], 0)
        val normal_n0 = test neg0 (IR.ZERO, true, [], 0)

        val normal_pinf = test posInf (IR.INF, false, [], 0)
        val normal_ninf = test negInf (IR.INF, true, [], 0)

        val normal_pnan = test posNan (IR.NAN, false, [], 0)
        val normal_nnan = test negNan (IR.NAN, true, [], 0)
      in () end

  end (* inner local *)

  (**********)

  local
    fun test arg expected =
        assertEqualRealOption expected (R.fromDecimal (makeDec arg))
  in

  (* safe case *)
  fun fromDecimal_normal_0001 () =
      let
        val normal_p_p = test (IR.NORMAL, false, [1, 2, 5], 2) (SOME 12.5)
        val normal_p_0 = test (IR.NORMAL, false, [1, 2, 5], 0) (SOME 0.125)
        val normal_p_n = test (IR.NORMAL, false, [1, 2, 5], ~2) (SOME 0.00125)

        val normal_n_p = test (IR.NORMAL, true, [1, 2, 5], 2) (SOME ~12.5)
        val normal_n_0 = test (IR.NORMAL, true, [1, 2, 5], 0) (SOME ~0.125)
        val normal_n_n = test (IR.NORMAL, true, [1, 2, 5], ~2) (SOME ~0.00125)
      in () end
  (* fromDecimal should ignore class field for IR.NORMAL. *)
  fun fromDecimal_normal_0002 () =
      let
        (* empty digits *)
        val abnormal_NORMAL_p0 = test (IR.NORMAL, false, [], 2) (SOME pos0)
        (* very large magnitude *)
        val abnormal_NORMAL_pinf = test (IR.NORMAL, false, [1], 1000) (SOME posInf)
        val abnormal_NORMAL_ninf = test (IR.NORMAL, true, [1], 1000) (SOME negInf)
        (* very small magnitude *)
        val abnormal_NORMAL_p0 = test (IR.NORMAL, false, [1], ~1000) (SOME pos0)
        val abnormal_NORMAL_n0 = test (IR.NORMAL, true, [1], ~1000) (SOME neg0)
      in () end
  (* error case *)
  fun fromDecimal_normal_1001 () =
      let
        val normal_invalid_digits = test (IR.NORMAL, false, [10], 0) NONE
      in () end

  (* safe case *)
  fun fromDecimal_abnormal_0001 () =
      let
        val normal_p0 = test (IR.ZERO, false, [], 0) (SOME pos0)
        val normal_n0 = test (IR.ZERO, true, [], 0) (SOME neg0)

        val normal_pinf = test (IR.INF, false, [], 0) (SOME posInf)
        val normal_ninf = test (IR.INF, true, [], 0) (SOME negInf)

        val normal_pnan = test (IR.NAN, false, [], 0) (SOME posNan)
        val normal_nnan = test (IR.NAN, true, [], 0) (SOME negNan)
      in () end
  fun fromDecimal_abnormal_0002 () =
      let
        (* digits and exp are ignored *)
        val abnormal_INF_p = test (IR.INF, false, [1, 2, 3], 2) (SOME posInf)
        val abnormal_NAN_p = test (IR.NAN, false, [1, 2, 3], 2) (SOME posNan)
      in () end

  end (* inner local *)

  end (* outer local *)

  (****************************************)

  fun suite () =
      T.labelTests
      [
        ("binArith_pos", binArith_pos),
        ("binArith_neg", binArith_neg),
        ("binArith_p0", binArith_p0),
        ("binArith_n0", binArith_n0),
        ("binArith_pinf", binArith_pinf),
        ("binArith_ninf", binArith_ninf),
        ("binArith_pnan", binArith_pnan),
        ("binArith_nnan", binArith_nnan),

        ("triArith0001", triArith0001),

        ("negation0001", negation0001),

        ("abs_normal", abs_normal),
        ("abs_zero", abs_zero),
        ("abs_inf", abs_inf),
        ("abs_nan", abs_nan),

        ("min_pos", min_pos),
        ("min_neg", min_neg),
        ("min_p0", min_p0),
        ("min_n0", min_n0),
        ("min_pinf", min_pinf),
        ("min_ninf", min_ninf),
        ("min_pnan", min_pnan),
        ("min_nnan", min_nnan),

        ("max_pos", max_pos),
        ("max_neg", max_neg),
        ("max_p0", max_p0),
        ("max_n0", max_n0),
        ("max_pinf", max_pinf),
        ("max_ninf", max_ninf),
        ("max_pnan", max_pnan),
        ("max_nnan", max_nnan),

        ("sign_normal", sign_normal),
        ("sign_zero", sign_zero),
        ("sign_inf", sign_inf),
        ("sign_nan", sign_nan),

        ("signBit_normal", signBit_normal),
        ("signBit_zero", signBit_zero),
        ("signBit_inf", signBit_inf),
        ("signBit_nan", signBit_nan),

        ("sameSign_normal", sameSign_normal),
        ("sameSign_zero", sameSign_zero),
        ("sameSign_inf", sameSign_inf),
        ("sameSign_nan", sameSign_nan),

        ("copySign_pos", copySign_pos),
        ("copySign_neg", copySign_neg),
        ("copySign_p0", copySign_p0),
        ("copySign_n0", copySign_n0),
        ("copySign_pinf", copySign_pinf),
        ("copySign_ninf", copySign_ninf),
        ("copySign_pnan", copySign_pnan),
        ("copySign_nnan", copySign_nnan),

        ("compare_pos", compare_pos),
        ("compare_neg", compare_neg),
        ("compare_p0", compare_p0),
        ("compare_n0", compare_n0),
        ("compare_pinf", compare_pinf),
        ("compare_ninf", compare_ninf),
        ("compare_pnan", compare_pnan),
        ("compare_nnan", compare_nnan),

        ("compareReal_pos", compareReal_pos),
        ("compareReal_neg", compareReal_neg),
        ("compareReal_p0", compareReal_p0),
        ("compareReal_n0", compareReal_n0),
        ("compareReal_pinf", compareReal_pinf),
        ("compareReal_ninf", compareReal_ninf),
        ("compareReal_pnan", compareReal_pnan),
        ("compareReal_nnan", compareReal_nnan),

        ("binComp_pos", binComp_pos),
        ("binComp_neg", binComp_neg),
        ("binComp_p0", binComp_p0),
        ("binComp_n0", binComp_n0),
        ("binComp_pinf", binComp_pinf),
        ("binComp_ninf", binComp_ninf),
        ("binComp_pnan", binComp_pnan),
        ("binComp_nnan", binComp_nnan),

        ("IEEEEq_pos", IEEEEq_pos),
        ("IEEEEq_neg", IEEEEq_neg),
        ("IEEEEq_p0", IEEEEq_p0),
        ("IEEEEq_n0", IEEEEq_n0),
        ("IEEEEq_pinf", IEEEEq_pinf),
        ("IEEEEq_ninf", IEEEEq_ninf),
        ("IEEEEq_pnan", IEEEEq_pnan),
        ("IEEEEq_nnan", IEEEEq_nnan),
        
        ("isFinite001", isFinite001),
        ("isNan001", isNan001),
        ("isNormal001", isNormal001),
        ("class001", class001),

        ("toManExp001", toManExp001),
        ("fromManExp001", fromManExp001),

        ("split001", split001),
        ("realMod001", realMod001),

        ("nextAfter001", nextAfter001),
        ("checkFloat001", checkFloat001),

        ("toRealIntConversions0001", toRealIntConversions0001),
        ("toIntConversions_normal_0001", toIntConversions_normal_0001),
        ("toIntConversions_normal_1001", toIntConversions_normal_1001),
        ("toIntConversions_normal_1002", toIntConversions_normal_1002),
        ("toIntConversions_normal_1003", toIntConversions_normal_1003),
        ("toIntConversions_inf", toIntConversions_inf),
        ("toIntConversions_nan", toIntConversions_nan),

        ("toInt_normal_0001", toInt_normal_0001),
        ("toInt_normal_0002", toInt_normal_0002),
        ("toInt_normal_1001", toInt_normal_1001),
        ("toInt_normal_1002", toInt_normal_1002),
        ("toInt_normal_1003", toInt_normal_1003),
        ("toInt_inf_0001", toInt_inf_0001),
        ("toInt_nan_0001", toInt_nan_0001),

        ("toLargeInt_normal_0001", toLargeInt_normal_0001),
        ("toLargeInt_normal_0002", toLargeInt_normal_0002),
        ("toLargeInt_normal_0003", toLargeInt_normal_0003),
        ("toLargeInt_inf_0001", toLargeInt_inf_0001),
        ("toLargeInt_nan_0001", toLargeInt_nan_0001),

        ("fromInt0001", fromInt0001),
        ("fromLargeInt0001", fromLargeInt0001),

        ("toLarge0001", toLarge0001),
        ("fromLarge0001", fromLarge0001),

        ("fmt_SCI_normal_0001", fmt_SCI_normal_0001),
        ("fmt_SCI_normal_0010", fmt_SCI_normal_0010),
        ("fmt_SCI_normal_0011", fmt_SCI_normal_0011),
        ("fmt_SCI_normal_0012", fmt_SCI_normal_0012),
        ("fmt_SCI_normal_0013", fmt_SCI_normal_0013),
        ("fmt_SCI_normal_0020", fmt_SCI_normal_0020),
        ("fmt_SCI_normal_0021", fmt_SCI_normal_0021),
        ("fmt_SCI_normal_0022", fmt_SCI_normal_0022),
        ("fmt_SCI_normal_0023", fmt_SCI_normal_0023),
        ("fmt_SCI_abnormal", fmt_SCI_abnormal),
        ("fmt_FIX_normal_0001", fmt_FIX_normal_0001),
        ("fmt_FIX_normal_0010", fmt_FIX_normal_0010),
        ("fmt_FIX_normal_0011", fmt_FIX_normal_0011),
        ("fmt_FIX_normal_0012", fmt_FIX_normal_0012),
        ("fmt_FIX_normal_0013", fmt_FIX_normal_0013),
        ("fmt_FIX_normal_0020", fmt_FIX_normal_0020),
        ("fmt_FIX_normal_0021", fmt_FIX_normal_0021),
        ("fmt_FIX_normal_0022", fmt_FIX_normal_0022),
        ("fmt_FIX_normal_0023", fmt_FIX_normal_0023),
        ("fmt_FIX_abnormal", fmt_FIX_abnormal),
        ("fmt_GEN_normal_NONE_posExp", fmt_GEN_normal_NONE_posExp),
        ("fmt_GEN_normal_NONE_negExp", fmt_GEN_normal_NONE_negExp),
        ("fmt_GEN_normal_SOME_posExp", fmt_GEN_normal_SOME_posExp),
        ("fmt_GEN_normal_SOME_negExp", fmt_GEN_normal_SOME_negExp),
        ("fmt_GEN_abnormal", fmt_GEN_abnormal),
        ("fmt_error", fmt_error),
        ("toString001", toString001),

        ("scan_normal_0001", scan_normal_0001),
        ("scan_normal_0002", scan_normal_0002),
        ("scan_normal_0003", scan_normal_0003),
        ("scan_normal_0010", scan_normal_0010),
        ("scan_normal_0011", scan_normal_0011),
        ("scan_normal_0012", scan_normal_0012),
        ("scan_normal_1001", scan_normal_1001),
        ("scan_abnormal_0001", scan_abnormal_0001),
        ("scan_abnormal_0002", scan_abnormal_0002),
        ("scan_abnormal_0010", scan_abnormal_0010),
        ("fromString0001", fromString0001),

        ("toDecimal_normal_0001", toDecimal_normal_0001),
        ("toDecimal_abnormal_0001", toDecimal_abnormal_0001),

        ("fromDecimal_normal_0001", fromDecimal_normal_0001),
        ("fromDecimal_normal_0002", fromDecimal_normal_0002),
        ("fromDecimal_normal_1001", fromDecimal_normal_1001),
        ("fromDecimal_abnormal_0001", fromDecimal_abnormal_0001),
        ("fromDecimal_abnormal_0002", fromDecimal_abnormal_0002)
      ]

  (************************************************************)

end