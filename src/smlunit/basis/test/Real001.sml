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
        val case_p_p as () = test (1.23, 2.46) (3.69, ~1.23, 3.0258, 0.5, 1.23)
        val case_p_n as () = test (1.23, ~2.46) (~1.23, 3.69, ~3.0258, ~0.5, 1.23)
        val case_p_p0 as () = test (1.23, pos0) (1.23, 1.23, pos0, posInf, posNan)
        val case_p_n0 as () = test (1.23, neg0) (1.23, 1.23, neg0, negInf, negNan)
        val case_p_pinf as () = test (1.23, posInf) (posInf, negInf, posInf, pos0, 1.23)
        val case_p_ninf as () = test (1.23, negInf) (negInf, posInf, negInf, neg0, 1.23)
        val case_p_pnan as () = test (1.23, posNan) (posNan, posNan, posNan, posNan, posNan)
        val case_p_nnan as () = test (1.23, negNan) (negNan, negNan, negNan, negNan, negNan)
      in () end
  fun binArith_neg () =
      let
        val case_n_p as () = test (~1.23, 2.46) (1.23, ~3.69, ~3.0258, ~0.5, ~1.23)
        val case_n_n as () = test (~1.23, ~2.46) (~3.69, 1.23, 3.0258, 0.5, ~1.23)
        val case_n_p0 as () = test (~1.23, pos0) (~1.23, ~1.23, neg0, negInf, negNan)
        val case_n_n0 as () = test (~1.23, neg0) (~1.23, ~1.23, pos0, posInf, posNan)
        val case_n_pinf as () = test (~1.23, posInf) (posInf, negInf, negInf, neg0, ~1.23)
        val case_n_ninf as () = test (~1.23, negInf) (negInf, posInf, posInf, pos0, ~1.23)
        val case_n_pnan as () = test (~1.23, posNan) (posNan, posNan, posNan, posNan, posNan)
        val case_n_nnan as () = test (~1.23, negNan) (negNan, negNan, negNan, negNan, negNan)
      in () end
  fun binArith_p0 () =
      let
        val case_p0_p as () = test (pos0, 2.46) (2.46, ~2.46, pos0, pos0, pos0)
        val case_p0_n as () = test (pos0, ~2.46) (~2.46, 2.46, neg0, neg0, pos0)
        val case_p0_p0 as () = test (pos0, pos0) (pos0, pos0, pos0, posNan, posNan)
        val case_p0_n0 as () = test (pos0, neg0) (pos0, pos0, neg0, negNan, negNan)
        val case_p0_pinf as () = test (pos0, posInf) (posInf, negInf, posNan, pos0, pos0)
        val case_p0_ninf as () = test (pos0, negInf) (negInf, posInf, negNan, neg0, pos0)
        val case_p0_pnan as () = test (pos0, posNan) (posNan, posNan, posNan, posNan, posNan)
        val case_p0_nnan as () = test (pos0, negNan) (negNan, negNan, negNan, negNan, negNan)
      in () end
  fun binArith_n0 () =
      let
        val case_n0_p as () = test (neg0, 2.46) (2.46, ~2.46, pos0, pos0, pos0)
        val case_n0_n as () = test (neg0, ~2.46) (~2.46, 2.46, neg0, neg0, pos0)
        val case_n0_p0 as () = test (neg0, pos0) (neg0, neg0, neg0, negNan, negNan)
        val case_n0_n0 as () = test (neg0, neg0) (neg0, neg0, pos0, posNan, negNan)
        val case_n0_pinf as () = test (neg0, posInf) (posInf, negInf, negNan, neg0, neg0)
        val case_n0_ninf as () = test (neg0, negInf) (negInf, posInf, posNan, pos0, neg0)
        val case_n0_pnan as () = test (neg0, posNan) (posNan, posNan, posNan, posNan, posNan)
        val case_n0_nnan as () = test (neg0, negNan) (negNan, negNan, negNan, negNan, negNan)
      in () end
  fun binArith_pinf () =
      let
        val case_pinf_p as () = test (posInf, 2.46) (posInf, posInf, posInf, posInf, posNan)
        val case_pinf_n as () = test (posInf, ~2.46) (posInf, posInf, negInf, negInf, posNan)
        val case_pinf_p0 as () = test (posInf, pos0) (posInf, posInf, posNan, posInf, posNan)
        val case_pinf_n0 as () = test (posInf, neg0) (posInf, posInf, negNan, negInf, negNan)
        val case_pinf_pinf as () = test (posInf, posInf) (posInf, posNan, posInf, posNan, posNan)
        val case_pinf_ninf as () = test (posInf, negInf) (posNan, posInf, negInf, negNan, posNan)
        val case_pinf_pnan as () = test (posInf, posNan) (posNan, posNan, posNan, posNan, posNan)
        val case_pinf_nnan as () = test (posInf, negNan) (negNan, negNan, negNan, negNan, negNan)
      in () end
  fun binArith_ninf () =
      let
        val case_ninf_p as () = test (negInf, 2.46) (negInf, negInf, negInf, negInf, negNan)
        val case_ninf_n as () = test (negInf, ~2.46) (negInf, negInf, posInf, posInf, negNan)
        val case_ninf_p0 as () = test (negInf, pos0) (negInf, negInf, negNan, negInf, negNan)
        val case_ninf_n0 as () = test (negInf, neg0) (negInf, negInf, posNan, posInf, posNan)
        val case_ninf_pinf as () = test (negInf, posInf) (negNan, negInf, negInf, negNan, negNan)
        val case_ninf_ninf as () = test (negInf, negInf) (negInf, negNan, posInf, posNan, posNan)
        val case_ninf_pnan as () = test (negInf, posNan) (posNan, posNan, posNan, posNan, posNan)
        val case_ninf_nnan as () = test (negInf, negNan) (negNan, negNan, negNan, negNan, negNan)
      in () end
  fun binArith_pnan () =
      let
        val case_pnan_p as () = test (posNan, 2.46) (posNan, posNan, posNan, posNan, posNan)
        val case_pnan_n as () = test (posNan, ~2.46) (posNan, posNan, posNan, posNan, posNan)
        val case_pnan_p0 as () = test (posNan, pos0) (posNan, posNan, posNan, posNan, posNan)
        val case_pnan_n0 as () = test (posNan, neg0) (posNan, posNan, posNan, posNan, posNan)
        val case_pnan_pinf as () = test (posNan, posInf) (posNan, posNan, posNan, posNan, posNan)
        val case_pnan_ninf as () = test (posNan, negInf) (posNan, posNan, posNan, posNan, posNan)
        val case_pnan_pnan as () = test (posNan, posNan) (posNan, posNan, posNan, posNan, posNan)
        val case_pnan_nnan as () = test (posNan, negNan) (posNan, posNan, posNan, posNan, posNan)
      in () end
  fun binArith_nnan () =
      let
        val case_nnan_p as () = test (negNan, 2.46) (posNan, posNan, posNan, posNan, posNan)
        val case_nnan_n as () = test (negNan, ~2.46) (posNan, posNan, posNan, posNan, posNan)
        val case_nnan_p0 as () = test (negNan, pos0) (posNan, posNan, posNan, posNan, posNan)
        val case_nnan_n0 as () = test (negNan, neg0) (posNan, posNan, posNan, posNan, posNan)
        val case_nnan_pinf as () = test (negNan, posInf) (posNan, posNan, posNan, posNan, posNan)
        val case_nnan_ninf as () = test (negNan, negInf) (posNan, posNan, posNan, posNan, posNan)
        val case_nnan_pnan as () = test (negNan, posNan) (posNan, posNan, posNan, posNan, posNan)
        val case_nnan_nnan as () = test (negNan, negNan) (posNan, posNan, posNan, posNan, posNan)
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
        val () = assertEqualReal (1.23 * 2.46 + 3.69) triArith_p_p_p_ma

        (* multiply-subtract *)
        val triArith_p_p_p_ms = R.*-(1.23, 2.46, 3.69)
        val () = assertEqualReal (1.23 * 2.46 - 3.69) triArith_p_p_p_ms
      in () end

  (**********)

  local fun test arg expected = assertEqualReal expected (R.~ arg)
  in
  fun negation0001 () =
      let
        val case_p as () = test 1.23 ~1.23
        val case_n as () = test ~1.23 1.23
        val case_p0 as () = test pos0 neg0
        val case_n0 as () = test neg0 pos0
        val case_pinf as () = test posInf negInf
        val case_ninf as () = test negInf posInf
        val case_pnan as () = test posNan negNan
        val case_nnan as () = test negNan posNan
      in () end
  end (* local *)

  (**********)

  local fun test arg expected = assertEqualReal expected (R.abs arg)
  in
  fun abs_normal () =
      let
        val case_p as () = test 1.23 1.23
        val case_m as () = test ~1.23 1.23
      in () end
  fun abs_zero () =
      let
        val case_p0 as () = test pos0 pos0
        val case_n0 as () = test neg0 pos0
      in () end
  fun abs_inf () =
      let
        val case_pinf as () = test posInf posInf
        val case_ninf as () = test negInf posInf
      in () end
  fun abs_nan () =
      let
        val case_pnan as () = test posNan posNan
        val case_nnan as () = test negNan posNan
      in () end
  end (* local *)

  (**********)

  local fun test arg expected = assertEqualReal expected (R.min arg)
  in
  fun min_pos () =
      let
        val case_p_p_l as () = test (1.23, 2.34) 1.23
        val case_p_p_g as () = test (2.34, 1.23) 1.23
        val case_p_n as () = test (1.23, ~2.34) ~2.34
        val case_p_p0 as () = test (1.23, pos0) pos0
        val case_p_n0 as () = test (1.23, neg0) neg0
        val case_p_pinf as () = test (1.23, posInf) 1.23
        val case_p_ninf as () = test (1.23, negInf) negInf
        val case_p_pnan as () = test (1.23, posNan) 1.23
        val case_p_nnan as () = test (1.23, negNan) 1.23
      in () end
  fun min_neg () =
      let
        val case_n_n_l as () = test (~2.34, ~1.23) ~2.34
        val case_n_n_g as () = test (~1.23, ~2.34) ~2.34
        val case_n_p as () = test (~2.34, 1.23) ~2.34
        val case_n_p0 as () = test (~1.23, pos0) ~1.23
        val case_n_n0 as () = test (~1.23, neg0) ~1.23
        val case_n_pinf as () = test (~1.23, posInf) ~1.23
        val case_n_ninf as () = test (~1.23, negInf) negInf
        val case_n_pnan as () = test (~1.23, posNan) ~1.23
        val case_n_nnan as () = test (~1.23, negNan) ~1.23
      in () end
  fun min_p0 () =
      let
        val case_p0_p as () = test (pos0, 1.23) pos0
        val case_p0_n as () = test (pos0, ~1.23) ~1.23
        val case_p0_p0 as () = test (pos0, pos0) pos0
        val case_p0_n0 as () = test (pos0, neg0) neg0
        val case_p0_pinf as () = test (pos0, posInf) pos0
        val case_p0_ninf as () = test (pos0, negInf) negInf
        val case_p0_pnan as () = test (pos0, posNan) pos0
        val case_p0_nnan as () = test (pos0, negNan) pos0
      in () end
  fun min_n0 () =
      let
        val case_n0_p as () = test (neg0, 1.23) neg0
        val case_n0_n as () = test (neg0, ~1.23) ~1.23
        val case_n0_p0 as () = test (neg0, pos0) neg0
        val case_n0_n0 as () = test (neg0, neg0) neg0
        val case_n0_pinf as () = test (neg0, posInf) neg0
        val case_n0_ninf as () = test (neg0, negInf) negInf
        val case_n0_pnan as () = test (neg0, posNan) neg0
        val case_n0_nnan as () = test (neg0, negNan) neg0
      in () end
  fun min_pinf () =
      let
        val case_pinf_p as () = test (posInf, 1.23) 1.23
        val case_pinf_n as () = test (posInf, ~1.23) ~1.23
        val case_pinf_p0 as () = test (posInf, pos0) pos0
        val case_pinf_n0 as () = test (posInf, neg0) neg0
        val case_pinf_pinf as () = test (posInf, posInf) posInf
        val case_pinf_ninf as () = test (posInf, negInf) negInf 
        val case_pinf_pnan as () = test (posInf, posNan) posInf
        val case_pinf_nnan as () = test (posInf, negNan) posInf
      in () end
  fun min_ninf () =
      let
        val case_ninf_p as () = test (negInf, 1.23) negInf
        val case_ninf_n as () = test (negInf, ~1.23) negInf
        val case_ninf_p0 as () = test (negInf, pos0) negInf
        val case_ninf_n0 as () = test (negInf, neg0) negInf
        val case_ninf_pinf as () = test (negInf, posInf) negInf
        val case_ninf_ninf as () = test (negInf, negInf) negInf 
        val case_ninf_pnan as () = test (negInf, posNan) negInf
        val case_ninf_nnan as () = test (negInf, negNan) negInf
      in () end
  fun min_pnan () =
      let
        val case_pnan_p as () = test (posNan, 1.23) 1.23
        val case_pnan_n as () = test (posNan, ~1.23) ~1.23
        val case_pnan_p0 as () = test (posNan, pos0) pos0
        val case_pnan_n0 as () = test (posNan, neg0) neg0
        val case_pnan_pinf as () = test (posNan, posInf) posInf
        val case_pnan_ninf as () = test (posNan, negInf) negInf 
        val case_pnan_pnan as () = test (posNan, posNan) posNan
        val case_pnan_nnan as () = test (posNan, negNan) posNan
      in () end
  fun min_nnan () =
      let
        val case_nnan_p as () = test (negNan, 1.23) 1.23
        val case_nnan_n as () = test (negNan, ~1.23) ~1.23
        val case_nnan_p0 as () = test (negNan, pos0) pos0
        val case_nnan_n0 as () = test (negNan, neg0) neg0
        val case_nnan_pinf as () = test (negNan, posInf) posInf
        val case_nnan_ninf as () = test (negNan, negInf) negInf 
        val case_nnan_pnan as () = test (negNan, posNan) negNan
        val case_nnan_nnan as () = test (negNan, negNan) negNan
      in () end

  end (* local min *)

  (**********)

  local fun test arg expected = assertEqualReal expected (R.max arg)
  in
  fun max_pos () =
      let
        val case_p_p_l as () = test (1.23, 2.34) 2.34
        val case_p_p_g as () = test (2.34, 1.23) 2.34
        val case_p_n as () = test (1.23, ~2.34) 1.23
        val case_p_p0 as () = test (1.23, pos0) 1.23
        val case_p_n0 as () = test (1.23, neg0) 1.23
        val case_p_pinf as () = test (1.23, posInf) posInf
        val case_p_ninf as () = test (1.23, negInf) 1.23
        val case_p_pnan as () = test (1.23, posNan) 1.23
        val case_p_nnan as () = test (1.23, negNan) 1.23
      in () end
  fun max_neg () =
      let
        val case_n_n_l as () = test (~2.34, ~1.23) ~1.23
        val case_n_n_g as () = test (~1.23, ~2.34) ~1.23
        val case_n_p as () = test (~2.34, 1.23) 1.23
        val case_n_p0 as () = test (~1.23, pos0) pos0
        val case_n_n0 as () = test (~1.23, neg0) neg0
        val case_n_pinf as () = test (~1.23, posInf) posInf
        val case_n_ninf as () = test (~1.23, negInf) ~1.23
        val case_n_pnan as () = test (~1.23, posNan) ~1.23
        val case_n_nnan as () = test (~1.23, negNan) ~1.23
      in () end
  fun max_p0 () =
      let
        val case_p0_p as () = test (pos0, 1.23) 1.23
        val case_p0_n as () = test (pos0, ~1.23) pos0
        val case_p0_p0 as () = test (pos0, pos0) pos0
        val case_p0_n0 as () = test (pos0, neg0) pos0
        val case_p0_pinf as () = test (pos0, posInf) posInf
        val case_p0_ninf as () = test (pos0, negInf) pos0
        val case_p0_pnan as () = test (pos0, posNan) pos0
        val case_p0_nnan as () = test (pos0, negNan) pos0
      in () end
  fun max_n0 () =
      let
        val case_n0_p as () = test (neg0, 1.23) 1.23
        val case_n0_n as () = test (neg0, ~1.23) neg0
        val case_n0_p0 as () = test (neg0, pos0) pos0
        val case_n0_n0 as () = test (neg0, neg0) neg0
        val case_n0_pinf as () = test (neg0, posInf) posInf
        val case_n0_ninf as () = test (neg0, negInf) neg0
        val case_n0_pnan as () = test (neg0, posNan) neg0
        val case_n0_nnan as () = test (neg0, negNan) neg0
      in () end
  fun max_pinf () =
      let
        val case_pinf_p as () = test (posInf, 1.23) posInf
        val case_pinf_n as () = test (posInf, ~1.23) posInf
        val case_pinf_p0 as () = test (posInf, pos0) posInf
        val case_pinf_n0 as () = test (posInf, neg0) posInf
        val case_pinf_pinf as () = test (posInf, posInf) posInf
        val case_pinf_ninf as () = test (posInf, negInf) posInf 
        val case_pinf_pnan as () = test (posInf, posNan) posInf
        val case_pinf_nnan as () = test (posInf, negNan) posInf
      in () end
  fun max_ninf () =
      let
        val case_ninf_p as () = test (negInf, 1.23) 1.23
        val case_ninf_n as () = test (negInf, ~1.23) ~1.23
        val case_ninf_p0 as () = test (negInf, pos0) pos0
        val case_ninf_n0 as () = test (negInf, neg0) neg0
        val case_ninf_pinf as () = test (negInf, posInf) posInf
        val case_ninf_ninf as () = test (negInf, negInf) negInf 
        val case_ninf_pnan as () = test (negInf, posNan) negInf
        val case_ninf_nnan as () = test (negInf, negNan) negInf
      in () end
  fun max_pnan () =
      let
        val case_pnan_p as () = test (posNan, 1.23) 1.23
        val case_pnan_n as () = test (posNan, ~1.23) ~1.23
        val case_pnan_p0 as () = test (posNan, pos0) pos0
        val case_pnan_n0 as () = test (posNan, neg0) neg0
        val case_pnan_pinf as () = test (posNan, posInf) posInf
        val case_pnan_ninf as () = test (posNan, negInf) negInf 
        val case_pnan_pnan as () = test (posNan, posNan) posNan
        val case_pnan_nnan as () = test (posNan, negNan) posNan
      in () end
  fun max_nnan () =
      let
        val case_nnan_p as () = test (negNan, 1.23) 1.23
        val case_nnan_n as () = test (negNan, ~1.23) ~1.23
        val case_nnan_p0 as () = test (negNan, pos0) pos0
        val case_nnan_n0 as () = test (negNan, neg0) neg0
        val case_nnan_pinf as () = test (negNan, posInf) posInf
        val case_nnan_ninf as () = test (negNan, negInf) negInf 
        val case_nnan_pnan as () = test (negNan, posNan) negNan
        val case_nnan_nnan as () = test (negNan, negNan) negNan
      in () end
  end (* local max *)

  (**********)

  local fun test arg expected = assertEqualInt expected (R.sign arg)
  in
  fun sign_normal () =
      let
        val case_p as () = test 1.23 1
        val case_n as () = test ~1.23 ~1
      in () end
  fun sign_zero () =
      let
        val case_p0 as () = test pos0 0
        val case_n0 as () = test neg0 0
      in () end
  fun sign_inf () =
      let
        val case_pinf as () = test posInf 1
        val case_ninf as () = test negInf ~1
      in () end
  fun sign_nan () =
      let
        val case_pnan as () =
            (R.sign posNan; fail "sign posnan") handle General.Domain => ()
        val case_nnan as () =
            (R.sign negNan; fail "sign negnan") handle General.Domain => ()
      in () end
  end (* local *)

  (**********)

  local fun test arg expected = assertEqualBool expected (R.signBit arg)
  in
  fun signBit_normal () =
      let
        val case_p as () = test 1.23 false
        val case_n as () = test ~1.23 true
      in () end
  fun signBit_zero () =
      let
        val case_p0 as () = test pos0 false
        val case_n0 as () = test neg0 true
      in () end
  fun signBit_inf () =
      let
        val case_pinf as () = test posInf false
        val case_ninf as () = test negInf true
      in () end
  fun signBit_nan () =
      let
        val case_pnan as () = test posNan false
        val case_nnan as () = test negNan true
      in () end
  end (* local *)

  (**********)

  local fun test arg expected = assertEqualBool expected (R.sameSign arg)
  in
  fun sameSign_normal () =
      let
        val case_p_p as () = test (1.23, 2.34) true 
        val case_p_n as () = test (1.23, ~2.34) false 
        val case_p_p0 as () = test (1.23, pos0) true 
        val case_p_n0 as () = test (1.23, neg0) false
        val case_p_pinf as () = test (1.23, posInf) true 
        val case_p_ninf as () = test (1.23, negInf) false
        val case_p_pnan as () = test (1.23, posNan) true 
        val case_p_nnan as () = test (1.23, negNan) false

        val case_n_p as () = test (~1.23, 2.34) false 
        val case_n_n as () = test (~1.23, ~2.34) true 
        val case_n_p0 as () = test (~1.23, pos0) false 
        val case_n_n0 as () = test (~1.23, neg0) true
        val case_n_pinf as () = test (~1.23, posInf) false 
        val case_n_ninf as () = test (~1.23, negInf) true
        val case_n_pnan as () = test (~1.23, posNan) false 
        val case_n_nnan as () = test (~1.23, negNan) true
      in () end
  fun sameSign_zero () =
      let
        val case_p0_p as () = test (pos0, 2.34) true 
        val case_p0_n as () = test (pos0, ~2.34) false 
        val case_p0_p0 as () = test (pos0, pos0) true 
        val case_p0_n0 as () = test (pos0, neg0) false
        val case_p0_pinf as () = test (pos0, posInf) true 
        val case_p0_ninf as () = test (pos0, negInf) false
        val case_p0_pnan as () = test (pos0, posNan) true 
        val case_p0_nnan as () = test (pos0, negNan) false

        val case_n0_p as () = test (neg0, 2.34) false
        val case_n0_n as () = test (neg0, ~2.34) true
        val case_n0_p0 as () = test (neg0, pos0) false
        val case_n0_n0 as () = test (neg0, neg0) true
        val case_n0_pinf as () = test (neg0, posInf) false
        val case_n0_ninf as () = test (neg0, negInf) true
        val case_n0_pnan as () = test (neg0, posNan) false
        val case_n0_nnan as () = test (neg0, negNan) true
      in () end
  fun sameSign_inf () =
      let
        val case_pinf_p as () = test (posInf, 1.0) true
        val case_pinf_n as () = test (posInf, ~1.0) false
        val case_pinf_p0 as () = test (posInf, pos0) true
        val case_pinf_n0 as () = test (posInf, neg0) false
        val case_pinf_pinf as () = test (posInf, posInf) true
        val case_pinf_ninf as () = test (posInf, negInf) false
        val case_pinf_pnan as () = test (posInf, posNan) true
        val case_pinf_nnan as () = test (posInf, negNan) false

        val case_ninf_p as () = test (negInf, 1.0) false
        val case_ninf_n as () = test (negInf, ~1.0) true
        val case_ninf_p0 as () = test (negInf, pos0) false
        val case_ninf_n0 as () = test (negInf, neg0) true
        val case_ninf_pinf as () = test (negInf, posInf) false
        val case_ninf_ninf as () = test (negInf, negInf) true
        val case_ninf_pnan as () = test (negInf, posNan) false
        val case_ninf_nnan as () = test (negInf, negNan) true
      in () end
  fun sameSign_nan () =
      let
        val case_pnan_p as () = test (posNan, 1.0) true
        val case_pnan_n as () = test (posNan, ~1.0) false
        val case_pnan_p0 as () = test (posNan, pos0) true
        val case_pnan_n0 as () = test (posNan, neg0) false
        val case_pnan_pinf as () = test (posNan, posInf) true
        val case_pnan_ninf as () = test (posNan, negInf) false
        val case_pnan_pnan as () = test (posNan, posNan) true
        val case_pnan_nnan as () = test (posNan, negNan) false

        val case_nnan_p as () = test (negNan, 1.0) false
        val case_nnan_n as () = test (negNan, ~1.0) true
        val case_nnan_p0 as () = test (negNan, pos0) false
        val case_nnan_n0 as () = test (negNan, neg0) true
        val case_nnan_pinf as () = test (negNan, posInf) false
        val case_nnan_ninf as () = test (negNan, negInf) true
        val case_nnan_pnan as () = test (negNan, posNan) false
        val case_nnan_nnan as () = test (negNan, negNan) true
      in () end

  end (* local *)
        
  (**********)

  local fun test arg expected = assertEqualReal expected (R.copySign arg)
  in
  fun copySign_pos () =
      let
        val case_p_p as () = test (1.23, 2.34) 1.23
        val case_p_n as () = test (1.23, ~2.34) ~1.23
        val case_p_p0 as () = test (1.23, pos0) 1.23
        val case_p_n0 as () = test (1.23, neg0) ~1.23
        val case_p_pinf as () = test (1.23, posInf) 1.23
        val case_p_ninf as () = test (1.23, negInf) ~1.23
        val case_p_pnan as () = test (1.23, posNan) 1.23
        val case_p_nnan as () = test (1.23, negNan) ~1.23
      in () end
  fun copySign_neg () =
      let
        val case_n_p as () = test (~1.23, 2.34) 1.23
        val case_n_n as () = test (~1.23, ~2.34) ~1.23
        val case_n_p0 as () = test (~1.23, pos0) 1.23
        val case_n_n0 as () = test (~1.23, neg0) ~1.23
        val case_n_pinf as () = test (~1.23, posInf) 1.23
        val case_n_ninf as () = test (~1.23, negInf) ~1.23
        val case_n_pnan as () = test (~1.23, posNan) 1.23
        val case_n_nnan as () = test (~1.23, negNan) ~1.23
      in () end
  fun copySign_p0 () =
      let
        val case_p0_p as () = test (pos0, 1.23) pos0
        val case_p0_n as () = test (pos0, ~1.23) neg0
        val case_p0_p0 as () = test (pos0, pos0) pos0
        val case_p0_n0 as () = test (pos0, neg0) neg0
        val case_p0_pinf as () = test (pos0, posInf) pos0
        val case_p0_ninf as () = test (pos0, negInf) neg0
        val case_p0_pnan as () = test (pos0, posNan) pos0
        val case_p0_nnan as () = test (pos0, negNan) neg0
      in () end
  fun copySign_n0 () =
      let
        val case_n0_p as () = test (neg0, 1.23) pos0
        val case_n0_n as () = test (neg0, ~1.23) neg0
        val case_n0_p0 as () = test (neg0, pos0) pos0
        val case_n0_n0 as () = test (neg0, neg0) neg0
        val case_n0_pinf as () = test (neg0, posInf) pos0
        val case_n0_ninf as () = test (neg0, negInf) neg0
        val case_n0_pnan as () = test (neg0, posNan) pos0
        val case_n0_nnan as () = test (neg0, negNan) neg0
      in () end
  fun copySign_pinf () =
      let
        val case_pinf_p as () = test (posInf, 1.23) posInf
        val case_pinf_n as () = test (posInf, ~1.23) negInf
        val case_pinf_p0 as () = test (posInf, pos0) posInf
        val case_pinf_n0 as () = test (posInf, neg0) negInf
        val case_pinf_pinf as () = test (posInf, posInf) posInf
        val case_pinf_ninf as () = test (posInf, negInf) negInf
        val case_pinf_pnan as () = test (posInf, posNan) posInf
        val case_pinf_nnan as () = test (posInf, negNan) negInf
      in () end
  fun copySign_ninf () =
      let
        val case_ninf_p as () = test (negInf, 1.23) posInf
        val case_ninf_n as () = test (negInf, ~1.23) negInf
        val case_ninf_p0 as () = test (negInf, pos0) posInf
        val case_ninf_n0 as () = test (negInf, neg0) negInf
        val case_ninf_pinf as () = test (negInf, posInf) posInf
        val case_ninf_ninf as () = test (negInf, negInf) negInf
        val case_ninf_pnan as () = test (negInf, posNan) posInf
        val case_ninf_nnan as () = test (negInf, negNan) negInf
      in () end
  fun copySign_pnan () =
      let
        val case_pnan_p as () = test (posNan, 1.23) posNan
        val case_pnan_n as () = test (posNan, ~1.23) negNan
        val case_pnan_p0 as () = test (posNan, pos0) posNan
        val case_pnan_n0 as () = test (posNan, neg0) negNan
        val case_pnan_pinf as () = test (posNan, posInf) posNan
        val case_pnan_ninf as () = test (posNan, negInf) negNan
        val case_pnan_pnan as () = test (posNan, posNan) posNan
        val case_pnan_nnan as () = test (posNan, negNan) negNan
      in () end
  fun copySign_nnan () =
      let
        val case_nnan_p as () = test (negNan, 1.23) posNan
        val case_nnan_n as () = test (negNan, ~1.23) negNan
        val case_nnan_p0 as () = test (negNan, pos0) posNan
        val case_nnan_n0 as () = test (negNan, neg0) negNan
        val case_nnan_pinf as () = test (negNan, posInf) posNan
        val case_nnan_ninf as () = test (negNan, negInf) negNan
        val case_nnan_pnan as () = test (negNan, posNan) posNan
        val case_nnan_nnan as () = test (negNan, negNan) negNan
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
        val case_p_p_l as () = test (1.23, 2.34) LESS
        val case_p_p_e as () = test (1.23, 1.23) EQUAL
        val case_p_p_g as () = test (2.34, 1.23) GREATER
        val case_p_n as () = test (1.23, ~2.34) GREATER
        val case_p_p0 as () = test (1.23, pos0) GREATER
        val case_p_n0 as () = test (1.23, neg0) GREATER
        val case_p_pinf as () = test (1.23, posInf) LESS
        val case_p_ninf as () = test (1.23, negInf) GREATER
        val case_p_pnan as () = testFail (1.23, posNan)
        val case_p_nnan as () = testFail (1.23, negNan)
      in () end
  fun compare_neg () =
      let
        val case_n_n_l as () = test (~2.34, ~1.23) LESS
        val case_n_n_e as () = test (~2.34, ~2.34) EQUAL
        val case_n_n_g as () = test (~1.23, ~2.34) GREATER
        val case_n_p as () = test (~2.34, 1.23) LESS
        val case_n_p0 as () = test (~1.23, pos0) LESS
        val case_n_n0 as () = test (~1.23, neg0) LESS
        val case_n_pinf as () = test (~1.23, posInf) LESS
        val case_n_ninf as () = test (~1.23, negInf) GREATER
        val case_n_pnan as () = testFail (~1.23, posNan) 
        val case_n_nnan as () = testFail (~1.23, negNan)
      in () end
  fun compare_p0 () =
      let
        val case_p0_p as () = test (pos0, 1.23) LESS
        val case_p0_n as () = test (pos0, ~1.23) GREATER
        val case_p0_p0 as () = test (pos0, pos0) EQUAL
        val case_p0_n0 as () = test (pos0, neg0) EQUAL
        val case_p0_pinf as () = test (pos0, posInf) LESS
        val case_p0_ninf as () = test (pos0, negInf) GREATER
        val case_p0_pnan as () = testFail (pos0, posNan) 
        val case_p0_nnan as () = testFail (pos0, negNan)
      in () end
  fun compare_n0 () =
      let
        val case_n0_p as () = test (neg0, 1.23) LESS
        val case_n0_n as () = test (neg0, ~1.23) GREATER
        val case_n0_p0 as () = test (neg0, pos0) EQUAL
        val case_n0_n0 as () = test (neg0, neg0) EQUAL
        val case_n0_pinf as () = test (neg0, posInf) LESS
        val case_n0_ninf as () = test (neg0, negInf) GREATER
        val case_n0_pnan as () = testFail (neg0, posNan)
        val case_n0_nnan as () = testFail (neg0, negNan)
      in () end
  fun compare_pinf () =
      let
        val case_pinf_p as () = test (posInf, 1.23) GREATER
        val case_pinf_n as () = test (posInf, ~1.23) GREATER
        val case_pinf_p0 as () = test (posInf, pos0) GREATER
        val case_pinf_n0 as () = test (posInf, neg0) GREATER
        val case_pinf_pinf as () = test (posInf, posInf) EQUAL
        val case_pinf_ninf as () = test (posInf, negInf) GREATER
        val case_pinf_pnan as () = testFail (posInf, posNan)
        val case_pinf_nnan as () = testFail (posInf, negNan)
      in () end
  fun compare_ninf () =
      let
        val case_ninf_p as () = test (negInf, 1.23) LESS
        val case_ninf_n as () = test (negInf, ~1.23) LESS
        val case_ninf_p0 as () = test (negInf, pos0) LESS
        val case_ninf_n0 as () = test (negInf, neg0) LESS
        val case_ninf_pinf as () = test (negInf, posInf) LESS
        val case_ninf_ninf as () = test (negInf, negInf) EQUAL
        val case_ninf_pnan as () = testFail (negInf, posNan)
        val case_ninf_nnan as () = testFail (negInf, negNan)
      in () end
  fun compare_pnan () =
      let
        val case_pnan_p as () = testFail (posNan, 1.23)
        val case_pnan_n as () = testFail (posNan, ~1.23)
        val case_pnan_p0 as () = testFail (posNan, pos0)
        val case_pnan_n0 as () = testFail (posNan, neg0)
        val case_pnan_pinf as () = testFail (posNan, posInf)
        val case_pnan_ninf as () = testFail (posNan, negInf)
        val case_pnan_pnan as () = testFail (posNan, posNan)
        val case_pnan_nnan as () = testFail (posNan, negNan)
      in () end
  fun compare_nnan () =
      let
        val case_nnan_p as () = testFail (negNan, 1.23)
        val case_nnan_n as () = testFail (negNan, ~1.23)
        val case_nnan_p0 as () = testFail (negNan, pos0)
        val case_nnan_n0 as () = testFail (negNan, neg0)
        val case_nnan_pinf as () = testFail (negNan, posInf)
        val case_nnan_ninf as () = testFail (negNan, negInf)
        val case_nnan_pnan as () = testFail (negNan, posNan)
        val case_nnan_nnan as () = testFail (negNan, negNan)
      in () end
  end (* local *)

  (**********)

  local
    fun test arg expected = assertEqualRealOrder expected (R.compareReal arg)
  in
  fun compareReal_pos () =
      let
        val case_p_p_l as () = test (1.23, 2.34) IR.LESS
        val case_p_p_e as () = test (1.23, 1.23) IR.EQUAL
        val case_p_p_g as () = test (2.34, 1.23) IR.GREATER
        val case_p_n as () = test (1.23, ~2.34) IR.GREATER
        val case_p_p0 as () = test (1.23, pos0) IR.GREATER
        val case_p_n0 as () = test (1.23, neg0) IR.GREATER
        val case_p_pinf as () = test (1.23, posInf) IR.LESS
        val case_p_ninf as () = test (1.23, negInf) IR.GREATER
        val case_p_pnan as () = test (1.23, posNan) IR.UNORDERED
        val case_p_nnan as () = test (1.23, negNan) IR.UNORDERED
      in () end
  fun compareReal_neg () =
      let
        val case_n_n_l as () = test (~2.34, ~1.23) IR.LESS
        val case_n_n_e as () = test (~2.34, ~2.34) IR.EQUAL
        val case_n_n_g as () = test (~1.23, ~2.34) IR.GREATER
        val case_n_p as () = test (~2.34, 1.23) IR.LESS
        val case_n_p0 as () = test (~1.23, pos0) IR.LESS
        val case_n_n0 as () = test (~1.23, neg0) IR.LESS
        val case_n_pinf as () = test (~1.23, posInf) IR.LESS
        val case_n_ninf as () = test (~1.23, negInf) IR.GREATER
        val case_n_pnan as () = test (~1.23, posNan)  IR.UNORDERED
        val case_n_nnan as () = test (~1.23, negNan) IR.UNORDERED
      in () end
  fun compareReal_p0 () =
      let
        val case_p0_p as () = test (pos0, 1.23) IR.LESS
        val case_p0_n as () = test (pos0, ~1.23) IR.GREATER
        val case_p0_p0 as () = test (pos0, pos0) IR.EQUAL
        val case_p0_n0 as () = test (pos0, neg0) IR.EQUAL
        val case_p0_pinf as () = test (pos0, posInf) IR.LESS
        val case_p0_ninf as () = test (pos0, negInf) IR.GREATER
        val case_p0_pnan as () = test (pos0, posNan)  IR.UNORDERED
        val case_p0_nnan as () = test (pos0, negNan) IR.UNORDERED
      in () end
  fun compareReal_n0 () =
      let
        val case_n0_p as () = test (neg0, 1.23) IR.LESS
        val case_n0_n as () = test (neg0, ~1.23) IR.GREATER
        val case_n0_p0 as () = test (neg0, pos0) IR.EQUAL
        val case_n0_n0 as () = test (neg0, neg0) IR.EQUAL
        val case_n0_pinf as () = test (neg0, posInf) IR.LESS
        val case_n0_ninf as () = test (neg0, negInf) IR.GREATER
        val case_n0_pnan as () = test (neg0, posNan) IR.UNORDERED
        val case_n0_nnan as () = test (neg0, negNan) IR.UNORDERED
      in () end
  fun compareReal_pinf () =
      let
        val case_pinf_p as () = test (posInf, 1.23) IR.GREATER
        val case_pinf_n as () = test (posInf, ~1.23) IR.GREATER
        val case_pinf_p0 as () = test (posInf, pos0) IR.GREATER
        val case_pinf_n0 as () = test (posInf, neg0) IR.GREATER
        val case_pinf_pinf as () = test (posInf, posInf) IR.EQUAL
        val case_pinf_ninf as () = test (posInf, negInf) IR.GREATER
        val case_pinf_pnan as () = test (posInf, posNan) IR.UNORDERED
        val case_pinf_nnan as () = test (posInf, negNan) IR.UNORDERED
      in () end
  fun compareReal_ninf () =
      let
        val case_ninf_p as () = test (negInf, 1.23) IR.LESS
        val case_ninf_n as () = test (negInf, ~1.23) IR.LESS
        val case_ninf_p0 as () = test (negInf, pos0) IR.LESS
        val case_ninf_n0 as () = test (negInf, neg0) IR.LESS
        val case_ninf_pinf as () = test (negInf, posInf) IR.LESS
        val case_ninf_ninf as () = test (negInf, negInf) IR.EQUAL
        val case_ninf_pnan as () = test (negInf, posNan) IR.UNORDERED
        val case_ninf_nnan as () = test (negInf, negNan) IR.UNORDERED
      in () end
  fun compareReal_pnan () =
      let
        val case_pnan_p as () = test (posNan, 1.23) IR.UNORDERED
        val case_pnan_n as () = test (posNan, ~1.23) IR.UNORDERED
        val case_pnan_p0 as () = test (posNan, pos0) IR.UNORDERED
        val case_pnan_n0 as () = test (posNan, neg0) IR.UNORDERED
        val case_pnan_pinf as () = test (posNan, posInf) IR.UNORDERED
        val case_pnan_ninf as () = test (posNan, negInf) IR.UNORDERED
        val case_pnan_pnan as () = test (posNan, posNan) IR.UNORDERED
        val case_pnan_nnan as () = test (posNan, negNan) IR.UNORDERED
      in () end
  fun compareReal_nnan () =
      let
        val case_nnan_p as () = test (negNan, 1.23) IR.UNORDERED
        val case_nnan_n as () = test (negNan, ~1.23) IR.UNORDERED
        val case_nnan_p0 as () = test (negNan, pos0) IR.UNORDERED
        val case_nnan_n0 as () = test (negNan, neg0) IR.UNORDERED
        val case_nnan_pinf as () = test (negNan, posInf) IR.UNORDERED
        val case_nnan_ninf as () = test (negNan, negInf) IR.UNORDERED
        val case_nnan_pnan as () = test (negNan, posNan) IR.UNORDERED
        val case_nnan_nnan as () = test (negNan, negNan) IR.UNORDERED
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
        val case_p_p_l as () = test (1.23, 2.34) TTFF
        val case_p_p_g as () = test (2.34, 1.23) FFTT
        val case_p_p_e as () = test (1.23, 1.23) FTTF
        val case_p_n as () = test (1.23, ~2.34) FFTT
        val case_p_p0 as () = test (1.23, pos0) FFTT
        val case_p_n0 as () = test (1.23, neg0) FFTT
        val case_p_pinf as () = test (1.23, posInf) TTFF
        val case_p_ninf as () = test (1.23, negInf) FFTT
        val case_p_pnan as () = test (1.23, posNan) FFFF
        val case_p_nnan as () = test (1.23, negNan) FFFF
      in () end
  fun binComp_neg () =
      let
        val case_n_n_l as () = test (~2.34, ~1.23) TTFF
        val case_n_n_g as () = test (~1.23, ~2.34) FFTT
        val case_n_n_e as () = test (~2.34, ~2.34) FTTF
        val case_n_p as () = test (~2.34, 1.23) TTFF
        val case_n_p0 as () = test (~1.23, pos0) TTFF
        val case_n_n0 as () = test (~1.23, neg0) TTFF
        val case_n_pinf as () = test (~1.23, posInf) TTFF
        val case_n_ninf as () = test (~1.23, negInf) FFTT
        val case_n_pnan as () = test (~1.23, posNan) FFFF
        val case_n_nnan as () = test (~1.23, negNan) FFFF
      in () end
  fun binComp_p0 () =
      let
        val case_p0_n as () = test (pos0, ~1.23) FFTT
        val case_p0_p as () = test (pos0, 1.23) TTFF
        val case_p0_p0 as () = test (pos0, pos0) FTTF
        val case_p0_n0 as () = test (pos0, neg0) FTTF
        val case_p0_pinf as () = test (pos0, posInf) TTFF
        val case_p0_ninf as () = test (pos0, negInf) FFTT
        val case_p0_pnan as () = test (pos0, posNan) FFFF
        val case_p0_nnan as () = test (pos0, negNan) FFFF
      in () end
  fun binComp_n0 () =
      let
        val case_n0_n as () = test (neg0, ~1.23) FFTT
        val case_n0_p as () = test (neg0, 1.23) TTFF
        val case_n0_p0 as () = test (neg0, pos0) FTTF
        val case_n0_n0 as () = test (neg0, neg0) FTTF
        val case_n0_pinf as () = test (neg0, posInf) TTFF
        val case_n0_ninf as () = test (neg0, negInf) FFTT
        val case_n0_pnan as () = test (neg0, posNan) FFFF
        val case_n0_nnan as () = test (neg0, negNan) FFFF
      in () end
  fun binComp_pinf () =
      let
        val case_pinf_n as () = test (posInf, ~1.23) FFTT
        val case_pinf_p as () = test (posInf, 1.23) FFTT
        val case_pinf_p0 as () = test (posInf, pos0) FFTT
        val case_pinf_n0 as () = test (posInf, neg0) FFTT
        val case_pinf_pinf as () = test (posInf, posInf) FTTF
        val case_pinf_ninf as () = test (posInf, negInf) FFTT
        val case_pinf_pnan as () = test (posInf, posNan) FFFF
        val case_pinf_nnan as () = test (posInf, negNan) FFFF
      in () end
  fun binComp_ninf () =
      let
        val case_ninf_n as () = test (negInf, ~1.23) TTFF
        val case_ninf_p as () = test (negInf, 1.23) TTFF
        val case_ninf_p0 as () = test (negInf, pos0) TTFF
        val case_ninf_n0 as () = test (negInf, neg0) TTFF
        val case_ninf_pinf as () = test (negInf, posInf) TTFF
        val case_ninf_ninf as () = test (negInf, negInf) FTTF
        val case_ninf_pnan as () = test (negInf, posNan) FFFF
        val case_ninf_nnan as () = test (negInf, negNan) FFFF
      in () end
  fun binComp_pnan () =
      let
        val case_pnan_n as () = test (posNan, ~1.23) FFFF
        val case_pnan_p as () = test (posNan, 1.23) FFFF
        val case_pnan_pnan as () = test (posNan, posNan) FFFF
        val case_pnan_nnan as () = test (posNan, negNan) FFFF
        val case_pnan_pinf as () = test (posNan, posInf) FFFF
        val case_pnan_ninf as () = test (posNan, negInf) FFFF
        val case_pnan_pnan as () = test (posNan, posNan) FFFF
        val case_pnan_nnan as () = test (posNan, negNan) FFFF
      in () end
  fun binComp_nnan () =
      let
        val case_nnan_n as () = test (negNan, ~1.23) FFFF
        val case_nnan_p as () = test (negNan, 1.23) FFFF
        val case_nnan_pnan as () = test (negNan, posNan) FFFF
        val case_nnan_nnan as () = test (negNan, negNan) FFFF
        val case_nnan_pinf as () = test (negNan, posInf) FFFF
        val case_nnan_ninf as () = test (negNan, negInf) FFFF
        val case_nnan_pnan as () = test (negNan, posNan) FFFF
        val case_nnan_nnan as () = test (negNan, negNan) FFFF
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
        val case_p_p_l as () = test (1.23, 2.34) FTFF
        val case_p_p_g as () = test (2.34, 1.23) FTFF
        val case_p_p_e as () = test (1.23, 1.23) TFTF
        val case_p_n as () = test (1.23, ~2.34) FTFF
        val case_p_p0 as () = test (1.23, pos0) FTFF
        val case_p_n0 as () = test (1.23, neg0) FTFF
        val case_p_pinf as () = test (1.23, posInf) FTFF
        val case_p_ninf as () = test (1.23, negInf) FTFF
        val case_p_pnan as () = test (1.23, posNan) FTTT
        val case_p_nnan as () = test (1.23, negNan) FTTT
      in () end
  fun IEEEEq_neg () =
      let
        val case_n_n_l as () = test (~2.34, ~1.23) FTFF
        val case_n_n_g as () = test (~1.23, ~2.34) FTFF
        val case_n_n_e as () = test (~2.34, ~2.34) TFTF
        val case_n_p as () = test (~2.34, 1.23) FTFF
        val case_n_p0 as () = test (~1.23, pos0) FTFF
        val case_n_n0 as () = test (~1.23, neg0) FTFF
        val case_n_pinf as () = test (~1.23, posInf) FTFF
        val case_n_ninf as () = test (~1.23, negInf) FTFF
        val case_n_pnan as () = test (~1.23, posNan) FTTT
        val case_n_nnan as () = test (~1.23, negNan) FTTT
      in () end
  fun IEEEEq_p0 () =
      let
        val case_p0_n as () = test (pos0, ~1.23) FTFF
        val case_p0_p as () = test (pos0, 1.23) FTFF
        val case_p0_p0 as () = test (pos0, pos0) TFTF
        val case_p0_n0 as () = test (pos0, neg0) TFTF
        val case_p0_pinf as () = test (pos0, posInf) FTFF
        val case_p0_ninf as () = test (pos0, negInf) FTFF
        val case_p0_pnan as () = test (pos0, posNan) FTTT
        val case_p0_nnan as () = test (pos0, negNan) FTTT
      in () end
  fun IEEEEq_n0 () =
      let
        val case_n0_n as () = test (neg0, ~1.23) FTFF
        val case_n0_p as () = test (neg0, 1.23) FTFF
        val case_n0_p0 as () = test (neg0, pos0) TFTF
        val case_n0_n0 as () = test (neg0, neg0) TFTF
        val case_n0_pinf as () = test (neg0, posInf) FTFF
        val case_n0_ninf as () = test (neg0, negInf) FTFF
        val case_n0_pnan as () = test (neg0, posNan) FTTT
        val case_n0_nnan as () = test (neg0, negNan) FTTT
      in () end
  fun IEEEEq_pinf () =
      let
        val case_pinf_n as () = test (posInf, ~1.23) FTFF
        val case_pinf_p as () = test (posInf, 1.23) FTFF
        val case_pinf_p0 as () = test (posInf, pos0) FTFF
        val case_pinf_n0 as () = test (posInf, neg0) FTFF
        val case_pinf_pinf as () = test (posInf, posInf) TFTF
        val case_pinf_ninf as () = test (posInf, negInf) FTFF
        val case_pinf_pnan as () = test (posInf, posNan) FTTT
        val case_pinf_nnan as () = test (posInf, negNan) FTTT
      in () end
  fun IEEEEq_ninf () =
      let
        val case_ninf_n as () = test (negInf, ~1.23) FTFF
        val case_ninf_p as () = test (negInf, 1.23) FTFF
        val case_ninf_p0 as () = test (negInf, pos0) FTFF
        val case_ninf_n0 as () = test (negInf, neg0) FTFF
        val case_ninf_pinf as () = test (negInf, posInf) FTFF
        val case_ninf_ninf as () = test (negInf, negInf) TFTF
        val case_ninf_pnan as () = test (negInf, posNan) FTTT
        val case_ninf_nnan as () = test (negInf, negNan) FTTT
      in () end
  fun IEEEEq_pnan () =
      let
        val case_pnan_n as () = test (posNan, ~1.23) FTTT
        val case_pnan_p as () = test (posNan, 1.23) FTTT
        val case_pnan_pnan as () = test (posNan, posNan) FTTT
        val case_pnan_nnan as () = test (posNan, negNan) FTTT
        val case_pnan_pinf as () = test (posNan, posInf) FTTT
        val case_pnan_ninf as () = test (posNan, negInf) FTTT
        val case_pnan_pnan as () = test (posNan, posNan) FTTT
        val case_pnan_nnan as () = test (posNan, negNan) FTTT
      in () end
  fun IEEEEq_nnan () =
      let
        val case_nnan_n as () = test (negNan, ~1.23) FTTT
        val case_nnan_p as () = test (negNan, 1.23) FTTT
        val case_nnan_pnan as () = test (negNan, posNan) FTTT
        val case_nnan_nnan as () = test (negNan, negNan) FTTT
        val case_nnan_pinf as () = test (negNan, posInf) FTTT
        val case_nnan_ninf as () = test (negNan, negInf) FTTT
        val case_nnan_pnan as () = test (negNan, posNan) FTTT
        val case_nnan_nnan as () = test (negNan, negNan) FTTT
      in () end
  end (* inner local *)

  end (* outer local *)

  (**********)

  local fun test arg expected = assertEqualBool expected (R.isFinite arg)
  in
  fun isFinite001 () =
      let
        val case_p as () = test 1.23 true
        val case_n as () = test ~2.34 true
        val case_p0 as () = test pos0 true
        val case_n0 as () = test neg0 true
        val case_pinf as () = test posInf false
        val case_ninf as () = test negInf false
        val case_pnan as () = test posNan false
        val case_nnan as () = test negNan false
      in () end
  end

  (**********)

  local fun test arg expected = assertEqualBool expected (R.isNan arg)
  in
  fun isNan001 () =
      let
        val case_p as () = test 1.23 false
        val case_n as () = test ~2.34 false
        val case_p0 as () = test pos0 false
        val case_n0 as () = test neg0 false
        val case_pinf as () = test posInf false
        val case_ninf as () = test negInf false
        val case_pnan as () = test posNan true
        val case_nnan as () = test negNan true
      in () end
  end

  (**********)

  local fun test arg expected = assertEqualBool expected (R.isNormal arg)
  in
  fun isNormal001 () =
      let
        val case_p as () = test 1.23 true
        val case_n as () = test ~2.34 true
        val case_p0 as () = test pos0 false
        val case_n0 as () = test neg0 false
        val case_pinf as () = test posInf false
        val case_ninf as () = test negInf false
        val case_pnan as () = test posNan false
        val case_nnan as () = test negNan false
      in () end
  end

  (**********)

  local fun test arg expected = assertEqualFloatClass expected (R.class arg)
  in
  fun class001 () =
      let
        (* ToDo : how to test SUBNORMAL ? *)
        val case_p as () = test 1.23 IR.NORMAL
        val case_n as () = test ~2.34 IR.NORMAL
        val case_p0 as () = test pos0 IR.ZERO
        val case_n0 as () = test neg0 IR.ZERO
        val case_pinf as () = test posInf IR.INF
        val case_ninf as () = test negInf IR.INF
        val case_pnan as () = test posNan IR.NAN
        val case_nnan as () = test negNan IR.NAN
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
        val case_p as () =
            test (0.567 * R.fromInt R.radix) {man = 0.567, exp = 1}
        val case_n as () =
            test (~0.567 * R.fromInt R.radix) {man = ~0.567, exp = 1}
        val case_p0 as () = test pos0 {man = pos0, exp = 0}
        val case_n0 as () = test neg0 {man = neg0, exp = 0}

        val case_pinf as () = testAbnormal posInf posInf
        val case_ninf as () = testAbnormal negInf negInf
        val case_pnan as () = testAbnormal posNan posNan
        val case_nnan as () = testAbnormal negNan negNan
      in () end
  end (* local *)

  (**********)

  local fun test arg expected = assertEqualReal expected (R.fromManExp arg)
  in
  fun fromManExp001 () =
      let
        val case_p0_0 as () = test {man = pos0, exp = 0} pos0
        val case_p0_p as () = test {man = pos0, exp = 4} pos0
        val case_p0_n as () = test {man = pos0, exp = ~4} pos0

        val case_n0_0 as () = test {man = neg0, exp = 0} neg0
        val case_n0_p as () = test {man = neg0, exp = 4} neg0
        val case_n0_n as () = test {man = neg0, exp = ~4} neg0

        val case_p_0 as () = test {man = 12.3, exp = 0} 12.3
        val case_p_p as () =
            test
                {man = 12.3, exp = 4}
                (12.3 * Math.pow(R.fromInt R.radix, 4.0))
        val case_p_n as () =
            test
                {man = 12.3, exp = ~4}
                (12.3 * Math.pow(R.fromInt R.radix, ~4.0))
        val case_n_0 as () = test {man = ~12.3, exp = 0} ~12.3
        val case_n_p as () =
            test
                {man = ~12.3, exp = 4}
                (~12.3 * Math.pow(R.fromInt R.radix, 4.0))
        val case_n_n as () =
            test
                {man = ~12.3, exp = ~4}
                (~12.3 * Math.pow(R.fromInt R.radix, ~4.0))
        val case_pinf_0 as () = test {man = posInf, exp = 0} posInf
        val case_pinf_p as () = test {man = posInf, exp = 4} posInf
        val case_pinf_n as () = test {man = posInf, exp = ~4} posInf

        val case_ninf_0 as () = test {man = negInf, exp = 0} negInf
        val case_ninf_p as () = test {man = negInf, exp = 4} negInf
        val case_ninf_n as () = test {man = negInf, exp = ~4} negInf

        val case_pnan_0 as () = test {man = posNan, exp = 0} posNan
        val case_pnan_p as () = test {man = posNan, exp = 4} posNan
        val case_pnan_n as () = test {man = posNan, exp = ~4} posNan

        val case_nnan_0 as () = test {man = negNan, exp = 0} negNan
        val case_nnan_p as () = test {man = negNan, exp = 4} negNan
        val case_nnan_n as () = test {man = negNan, exp = ~4} negNan
      in () end
  end (* local *)

  (**********)

  local fun test arg expected = assertEqualWholeFrac expected (R.split arg)
  in
  fun split001 () =
      let
        val case_p as () = test 123.456 {whole = 123.0, frac = 0.456}
        val case_n as () = test ~123.456 {whole = ~123.0, frac = ~0.456}
        val case_p0 as () = test pos0 {whole = pos0, frac = pos0}
        val case_n0 as () = test neg0 {whole = neg0, frac = neg0}
        (* If r is +-infinity, whole is +-infinity and frac is +-0. *)
        val case_pinf as () = test posInf {whole = posInf, frac = pos0}
        val case_ninf as () = test negInf {whole = negInf, frac = neg0}
        (* If r is NaN, both whole and frac are NaN. *)
        val case_pnan as () = test posNan {whole = posNan, frac = posNan}
        val case_nnan as () = test negNan {whole = negNan, frac = negNan}
      in () end
  end (* local *)

  (**********)

  local fun test arg expected = assertEqualReal expected (R.realMod arg)
  in
  fun realMod001 () =
      let
        val case_p as () = test 123.456 0.456
        val case_n as () = test ~123.456 ~0.456
        val case_p0 as () = test pos0 pos0
        val case_n0 as () = test neg0 neg0
        val case_pinf as () = test posInf pos0
        val case_ninf as () = test negInf neg0
        val case_pnan as () = test posNan posNan
        val case_nnan as () = test negNan negNan
      in () end
  end (* local *)

  (**********)

  local
    fun testNormal (arg1, arg2) expected =
        let
          val r = R.nextAfter (arg1, arg2)
          val () = assertEqualOrder expected (Real.compare(r, arg1))
        in () end
    fun testAbnormal (arg1, arg2) expected =
        assertEqualReal expected (R.nextAfter (arg1, arg2))
  in
  fun nextAfter001 () =
      let
        val case_p_l as () = testNormal (1.23, 1.0) LESS
        val case_p_e as () = testNormal (1.23, 1.23) EQUAL
        val case_p_g as () = testNormal (1.23, 2.0) GREATER
        val case_n_l as () = testNormal (~1.23, ~2.0) LESS
        val case_n_e as () = testNormal (~1.23, ~1.23) EQUAL
        val case_n_g as () = testNormal (~1.23, ~1.0) GREATER
        val case_p0_l as () = testNormal (pos0, ~1.0) LESS
        val case_p0_e as () = testNormal (pos0, pos0) EQUAL
        val case_p0_g as () = testNormal (pos0, 1.0) GREATER
        val case_n0_l as () = testNormal (neg0, ~1.0) LESS
        val case_n0_e as () = testNormal (neg0, neg0) EQUAL
        val case_n0_g as () = testNormal (neg0, 1.0) GREATER

(*
        val case_pinf as () = testAbnormal (posInf, 0.0) posInf
        val case_ninf as () = testAbnormal (negInf, 0.0) negInf
*)
        val case_pinf as () = testAbnormal (posInf, 0.0) Real.maxFinite
        val case_ninf as () = testAbnormal (negInf, 0.0) (~ Real.maxFinite)
        val case_pnan as () = testAbnormal (posNan, 0.0) posNan
        val case_nnan as () = testAbnormal (negNan, 0.0) negNan
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
        val case_p as () = test 1.23 1.23
        val case_n as () = test ~2.34 ~2.34
        val case_p0 as () = test pos0 pos0
        val case_n0 as () = test neg0 neg0

        val case_pinf as () = testFailByOverflow posInf
        val case_ninf as () = testFailByOverflow negInf

        val case_pnan as () = testFailByDiv posNan
        val case_nnan as () = testFailByDiv negNan
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
        val case_p_14 as () = test 1.4 (1.0, 2.0, 1.0, 1.0)
        val case_p_15 as () = test 1.5 (1.0, 2.0, 1.0, 2.0)
        val case_n_14 as () = test ~1.4 (~2.0, ~1.0, ~1.0, ~1.0)
        val case_n_15 as () = test ~1.5 (~2.0, ~1.0, ~1.0, ~2.0)

        val case_p0 as () = test pos0 (pos0, pos0, pos0, pos0)
        val case_n0 as () = test neg0 (neg0, neg0, neg0, neg0)
        val case_pInf as () = test posInf (posInf, posInf, posInf, posInf)
        val case_nInf as () = test negInf (negInf, negInf, negInf, negInf)
        val case_pNan as () = test posNan (posNan, posNan, posNan, posNan)
        val case_nNan as () = test negNan (negNan, negNan, negNan, negNan)
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
        val case_p_14 as () = test 1.4 (1, 2, 1, 1)
        val case_p_15 as () = test 1.5 (1, 2, 1, 2)
        val case_n_14 as () = test ~1.4 (~2, ~1, ~1, ~1)
        val case_n_15 as () = test ~1.5 (~2, ~1, ~1, ~2)

        val case_p0 as () = test pos0 (0, 0, 0, 0)
        val case_n0 as () = test neg0 (0, 0, 0, 0)
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

        val case_pinf_floor as () = testFail R.floor maxIntPlus1_r
        val case_pinf_ceil as () = testFail R.ceil maxIntPlus1_r
        val case_pinf_trunc as () = testFail R.trunc maxIntPlus1_r
        val case_pinf_round as () = testFail R.round maxIntPlus1_r

        val case_ninf_floor as () = testFail R.floor minIntMinus1_r
        val case_ninf_ceil as () = testFail R.ceil minIntMinus1_r
        val case_ninf_trunc as () = testFail R.trunc minIntMinus1_r
        val case_ninf_round as () = testFail R.round minIntMinus1_r
      in () end
  fun toIntConversions_normal_1002 () =
      let
        (* round succeeds. *)
        val maxIntPlus04_r = maxInt_r + 0.4
        val minIntMinus04_r = minInt_r - 0.4

        val case_pinf_floor as () = test R.floor maxIntPlus04_r maxInt
        val case_pinf_ceil as () = testFail R.ceil maxIntPlus04_r
        val case_pinf_trunc as () = test R.trunc maxIntPlus04_r maxInt
        val case_pinf_round as () = test R.round maxIntPlus04_r maxInt

        val case_ninf_floor as () = testFail R.floor minIntMinus04_r
        val case_ninf_ceil as () = test R.ceil minIntMinus04_r minInt
        val case_ninf_trunc as () = test R.trunc minIntMinus04_r minInt
        val case_ninf_round as () = test R.round minIntMinus04_r minInt
      in () end
  fun toIntConversions_normal_1003 () =
      let
        (* round fails *)
        val maxIntPlus06_r = maxInt_r + 0.6
        val minIntMinus06_r = minInt_r - 0.6

        val case_pinf_floor as () = test R.floor maxIntPlus06_r maxInt
        val case_pinf_ceil as () = testFail R.ceil maxIntPlus06_r
        val case_pinf_trunc as () = test R.trunc maxIntPlus06_r maxInt
        val case_pinf_round as () = testFail R.round maxIntPlus06_r

        val case_ninf_floor as () = testFail R.floor minIntMinus06_r
        val case_ninf_ceil as () = test R.ceil minIntMinus06_r minInt
        val case_ninf_trunc as () = test R.trunc minIntMinus06_r minInt
        val case_ninf_round as () = testFail R.round minIntMinus06_r
      in () end
  end (* local *)

  local
    fun testFail conv arg =
        (conv arg; fail "Overflow expected") handle General.Overflow => ()
  in
  fun toIntConversions_inf () =
      let
        val case_pinf_floor as () = testFail R.floor posInf
        val case_pinf_ceil as () = testFail R.ceil posInf
        val case_pinf_trunc as () = testFail R.trunc posInf
        val case_pinf_round as () = testFail R.round posInf

        val case_ninf_floor as () = testFail R.floor negInf
        val case_ninf_ceil as () = testFail R.ceil negInf
        val case_ninf_trunc as () = testFail R.trunc negInf
        val case_ninf_round as () = testFail R.round negInf
      in () end
  end (* local *)

  local
    fun testFail conv arg =
        (conv arg; fail "Domain expected") handle General.Domain => ()
  in
  fun toIntConversions_nan () =
      let
        val case_pnan_floor as () = testFail R.floor posNan
        val case_pnan_ceil as () = testFail R.ceil posNan
        val case_pnan_trunc as () = testFail R.trunc posNan
        val case_pnan_round as () = testFail R.round posNan

        val case_nnan_floor as () = testFail R.floor negNan
        val case_nnan_ceil as () = testFail R.ceil negNan
        val case_nnan_trunc as () = testFail R.trunc negNan
        val case_nnan_round as () = testFail R.round negNan
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
        val case_p14 as () = test 1.4 (1, 1, 2, 1)
        val case_p15 as () = test 1.5 (2, 1, 2, 1)
        val case_n14 as () = test ~1.4 (~1, ~2, ~1, ~1)
        val case_n15 as () = test ~1.5 (~2, ~2, ~1, ~1)
        val case_p0 as () = test pos0 (0, 0, 0, 0)
        val case_n0 as () = test neg0 (0, 0, 0, 0)
      in () end
  fun toInt_normal_0002 () =
      let
        val case_maxInt as () = test maxInt_r (maxInt, maxInt, maxInt, maxInt)
        val case_minInt as () = test minInt_r (minInt, minInt, minInt, minInt)
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

        val case_pinf_NEAREST as () = testFail IR.TO_NEAREST maxIntPlus1_r
        val case_pinf_NEGINF as () = testFail IR.TO_NEGINF maxIntPlus1_r
        val case_pinf_POSINF as () = testFail IR.TO_POSINF maxIntPlus1_r
        val case_pinf_ZERO as () = testFail IR.TO_ZERO maxIntPlus1_r

        val case_ninf_NEAREST as () = testFail IR.TO_NEAREST minIntMinus1_r
        val case_ninf_NEGINF as () = testFail IR.TO_NEGINF minIntMinus1_r
        val case_ninf_POSINF as () = testFail IR.TO_POSINF minIntMinus1_r
        val case_ninf_ZERO as () = testFail IR.TO_ZERO minIntMinus1_r
      in () end
  fun toInt_normal_1002 () =
      let
        (* TO_NEAREST succeeds. *)
        val maxIntPlus04_r = maxInt_r + 0.4
        val minIntMinus04_r = minInt_r - 0.4

        val case_pinf_NEAREST as () = test IR.TO_NEAREST maxIntPlus04_r maxInt
        val case_pinf_NEGINF as () = test IR.TO_NEGINF maxIntPlus04_r maxInt
        val case_pinf_POSINF as () = testFail IR.TO_POSINF maxIntPlus04_r
        val case_pinf_ZERO as () = test IR.TO_ZERO maxIntPlus04_r maxInt

        val case_ninf_NEAREST as () = test IR.TO_NEAREST minIntMinus04_r minInt
        val case_ninf_NEGINF as () = testFail IR.TO_NEGINF minIntMinus04_r
        val case_ninf_POSINF as () = test IR.TO_POSINF minIntMinus04_r minInt
        val case_ninf_ZERO as () = test IR.TO_ZERO minIntMinus04_r minInt
      in () end
  fun toInt_normal_1003 () =
      let
        (* TO_NEAREST fails *)
        val maxIntPlus06_r = maxInt_r + 0.6
        val minIntMinus06_r = minInt_r - 0.6

        val case_pinf_NEAREST as () = testFail IR.TO_NEAREST maxIntPlus06_r
        val case_pinf_NEGINF as () = test IR.TO_NEGINF maxIntPlus06_r maxInt
        val case_pinf_POSINF as () = testFail IR.TO_POSINF maxIntPlus06_r
        val case_pinf_ZERO as () = test IR.TO_ZERO maxIntPlus06_r maxInt

        val case_ninf_NEAREST as () = testFail IR.TO_NEAREST minIntMinus06_r
        val case_ninf_NEGINF as () = testFail IR.TO_NEGINF minIntMinus06_r
        val case_ninf_POSINF as () = test IR.TO_POSINF minIntMinus06_r minInt
        val case_ninf_ZERO as () = test IR.TO_ZERO minIntMinus06_r minInt
      in () end
  end (* local *)

  local
    fun test mode arg =
        (R.toInt mode arg; fail "Overflow expected")
        handle General.Overflow => ()
  in
  fun toInt_inf_0001 () =
      let
        val case_pinf_NEAREST as () = test IR.TO_NEAREST posInf
        val case_pinf_NEGINF as () = test IR.TO_NEGINF posInf
        val case_pinf_POSINF as () = test IR.TO_POSINF posInf
        val case_pinf_ZERO as () = test IR.TO_ZERO posInf

        val case_ninf_NEAREST as () = test IR.TO_NEAREST negInf
        val case_ninf_NEGINF as () = test IR.TO_NEGINF negInf
        val case_ninf_POSINF as () = test IR.TO_POSINF negInf
        val case_ninf_ZERO as () = test IR.TO_ZERO negInf
      in () end
  end (* local *)

  local
    fun test mode arg =
        (R.toInt mode arg; fail "Domain expected") handle General.Domain => ()
  in
  fun toInt_nan_0001 () =
      let
        val case_pnan_NEAREST as () = test IR.TO_NEAREST posNan
        val case_pnan_NEGINF as () = test IR.TO_NEGINF posNan
        val case_pnan_POSINF as () = test IR.TO_POSINF posNan
        val case_pnan_ZERO as () = test IR.TO_ZERO posNan

        val case_nnan_NEAREST as () = test IR.TO_NEAREST negNan
        val case_nnan_NEGINF as () = test IR.TO_NEGINF negNan
        val case_nnan_POSINF as () = test IR.TO_POSINF negNan
        val case_nnan_ZERO as () = test IR.TO_ZERO negNan
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
        val case_p14 as () = test 1.4 (1, 1, 2, 1)
        val case_p15 as () = test 1.5 (2, 1, 2, 1)
        val case_n14 as () = test ~1.4 (~1, ~2, ~1, ~1)
        val case_n15 as () = test ~1.5 (~2, ~2, ~1, ~1)
        val case_p0 as () = test pos0 (0, 0, 0, 0)
        val case_n0 as () = test neg0 (0, 0, 0, 0)
      in () end
  fun toLargeInt_normal_0002 () =
      (* test Int.maxInt. *)
      let
        val maxInt = maxInt_L
        val minInt = minInt_L
        val case_maxInt as () = test maxInt_r (maxInt, maxInt, maxInt, maxInt)
        val case_minInt as () = test minInt_r (minInt, minInt, minInt, minInt)
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
          val case_maxInt as () =
              test maxIntP1_r (maxIntP1, maxIntP1, maxIntP1, maxIntP1)
          val case_minInt as () =
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
        val case_pinf_NEAREST as () = test IR.TO_NEAREST posInf
        val case_pinf_NEGINF as () = test IR.TO_NEGINF posInf
        val case_pinf_POSINF as () = test IR.TO_POSINF posInf
        val case_pinf_ZERO as () = test IR.TO_ZERO posInf

        val case_ninf_NEAREST as () = test IR.TO_NEAREST negInf
        val case_ninf_NEGINF as () = test IR.TO_NEGINF negInf
        val case_ninf_POSINF as () = test IR.TO_POSINF negInf
        val case_ninf_ZERO as () = test IR.TO_ZERO negInf
      in () end
  end (* local *)

  local
    fun test mode arg =
        (R.toLargeInt mode arg; fail "Domain expected")
        handle General.Domain => ()
  in
  fun toLargeInt_nan_0001 () =
      let
        val case_pnan_NEAREST as () = test IR.TO_NEAREST posNan
        val case_pnan_NEGINF as () = test IR.TO_NEGINF posNan
        val case_pnan_POSINF as () = test IR.TO_POSINF posNan
        val case_pnan_ZERO as () = test IR.TO_ZERO posNan

        val case_nnan_NEAREST as () = test IR.TO_NEAREST negNan
        val case_nnan_NEGINF as () = test IR.TO_NEGINF negNan
        val case_nnan_POSINF as () = test IR.TO_POSINF negNan
        val case_nnan_ZERO as () = test IR.TO_ZERO negNan
      in () end
  end (* local *)

  (**********)

  fun fromInt0001 () =
      let
        val fromInt_p = R.fromInt 123
        val () = assertEqualReal 123.0 fromInt_p

        val fromInt_n = R.fromInt ~123
        val () = assertEqualReal ~123.0 fromInt_n

        val fromInt_0 = R.fromInt 0
        val () = assertEqualReal pos0 fromInt_0
      in () end

  (**********)

  fun fromLargeInt0001 () =
      let
        val fromLargeInt_p = R.fromLargeInt 123
        val () = assertEqualReal 123.0 fromLargeInt_p

        val fromLargeInt_n = R.fromLargeInt ~123
        val () = assertEqualReal ~123.0 fromLargeInt_n

        val fromLargeInt_0 = R.fromLargeInt 0
        val () = assertEqualReal pos0 fromLargeInt_0
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
        val case_p as () = test 1.23 1.23
        val case_n as () = test ~1.23 ~1.23
        val case_p0 as () = test pos0 0.0
        val case_n0 as () = test pos0 ~0.0
        val case_pinf as () = test posInf LR.posInf
        val case_ninf as () = test negInf LR.negInf
        val case_pnan as () = test posNan largePosNan
        val case_nnan as () = test negNan largeNegNan
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
        val case_p14 as () = test 1.4 (1.4, 1.4, 1.4, 1.4)
        val case_p15 as () = test 1.5 (1.5, 1.5, 1.5, 1.5)
        val case_n14 as () = test ~1.4 (~1.4, ~1.4, ~1.4, ~1.4)
        val case_n15 as () = test ~1.5 (~1.5, ~1.5, ~1.5, ~1.5)
        val case_p0 as () = test 0.0 (pos0, pos0, pos0, pos0)
        val case_n0 as () = test ~0.0 (neg0, neg0, neg0, neg0)
        val case_pinf as () = test LR.posInf (posInf, posInf, posInf, posInf)
        val case_ninf as () = test LR.negInf (negInf, negInf, negInf, negInf)
        val case_pnan as () = test largePosNan (posNan, posNan, posNan, posNan)
        val case_nnan as () = test largeNegNan (negNan, negNan, negNan, negNan)
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
        val case_SCI_1875_N_1 as () = test (SCI NONE) 18.75 "1.875000E1"
(*
        val case_SCI_1875_0_1 as () = test (SCI (SOME 0)) 18.75 "1E1"
        val case_SCI_1875_0_1 as () = test (SCI (SOME 0)) 18.75 "2E1"
        val case_SCI_1875_1_1 as () = test (SCI (SOME 1)) 18.75 "1.8E1"
        val case_SCI_1875_2_1 as () = test (SCI (SOME 2)) 18.75 "1.87E1"
        val case_SCI_1875_3_1 as () = test (SCI (SOME 3)) 18.75 "1.875E1"
        val case_SCI_1875_4_1 as () = test (SCI (SOME 4)) 18.75 "1.8750E1"
*)
        val case_SCI_1875_0_1 as () = test (SCI (SOME 0)) 18.75 "2E1"
        val case_SCI_1875_1_1 as () = test (SCI (SOME 1)) 18.75 "1.9E1"
        val case_SCI_1875_2_1 as () = test (SCI (SOME 2)) 18.75 "1.88E1"
        val case_SCI_1875_3_1 as () = test (SCI (SOME 3)) 18.75 "1.875E1"
        val case_SCI_1875_4_1 as () = test (SCI (SOME 4)) 18.75 "1.8750E1"

        val case_SCI_1875_N_0 as () = test (SCI NONE) 1.875 "1.875000E0"
        val case_SCI_1875_N_n1 as () = test (SCI NONE) 0.1875 "1.875000E~1"

        val case_SCI_n1875_N_1 as () = test (SCI NONE) ~18.75 "~1.875000E1"
      in () end
  (* check exponential. The real is just on power of 10. *)
  fun fmt_SCI_normal_0010 () =
      let
        val case_SCI_100_N_1 as () = test (SCI NONE) 10.0 "1.000000E1"
        val case_SCI_100_0_1 as () = test (SCI (SOME 0)) 10.0 "1E1"
        val case_SCI_100_1_1 as () = test (SCI (SOME 1)) 10.0 "1.0E1"
        val case_SCI_100_2_1 as () = test (SCI (SOME 2)) 10.0 "1.00E1"
        val case_SCI_100_3_1 as () = test (SCI (SOME 3)) 10.0 "1.000E1"
      in () end
  (* check rounding. The most significant digit is under 5 *)
  fun fmt_SCI_normal_0011 () =
      let
        val case_SCI_400_N_1 as () = test (SCI NONE) 40.0 "4.000000E1"
        val case_SCI_400_0_1 as () = test (SCI (SOME 0)) 40.0 "4E1"
        val case_SCI_400_1_1 as () = test (SCI (SOME 1)) 40.0 "4.0E1"
        val case_SCI_400_2_1 as () = test (SCI (SOME 2)) 40.0 "4.00E1"
        val case_SCI_400_3_1 as () = test (SCI (SOME 3)) 40.0 "4.000E1"
      in () end
  (* check rounding. The most significant digit is over 5 *)
  fun fmt_SCI_normal_0012 () =
      let
        val case_SCI_600_N_1 as () = test (SCI NONE) 60.0 "6.000000E1"
        val case_SCI_600_0_1 as () = test (SCI (SOME 0)) 60.0 "6E1"
        val case_SCI_600_1_1 as () = test (SCI (SOME 1)) 60.0 "6.0E1"
        val case_SCI_600_2_1 as () = test (SCI (SOME 2)) 60.0 "6.00E1"
        val case_SCI_600_3_1 as () = test (SCI (SOME 3)) 60.0 "6.000E1"
      in () end
  (* check sign *)
  fun fmt_SCI_normal_0013 () =
      let
        val case_SCI_n100_N_1 as () = test (SCI NONE) ~10.0 "~1.000000E1"
        val case_SCI_n100_0_1 as () = test (SCI (SOME 0)) ~10.0 "~1E1"
        val case_SCI_n100_1_1 as () = test (SCI (SOME 1)) ~10.0 "~1.0E1"
        val case_SCI_n100_2_1 as () = test (SCI (SOME 2)) ~10.0 "~1.00E1"
        val case_SCI_n100_3_1 as () = test (SCI (SOME 3)) ~10.0 "~1.000E1"
      in () end
  (* check exponential. The real is just on power of 10. *)
  fun fmt_SCI_normal_0020 () =
      let
        val case_SCI_0001_N_n3 as () = test (SCI NONE) 0.001 "1.000000E~3"
        val case_SCI_0001_0_n3 as () = test (SCI (SOME 0)) 0.001 "1E~3"
        val case_SCI_0001_1_n3 as () = test (SCI (SOME 1)) 0.001 "1.0E~3"
        val case_SCI_0001_2_n3 as () = test (SCI (SOME 2)) 0.001 "1.00E~3"
        val case_SCI_0001_3_n3 as () = test (SCI (SOME 3)) 0.001 "1.000E~3"
        val case_SCI_0001_4_n3 as () = test (SCI (SOME 4)) 0.001 "1.0000E~3"
      in () end
  (* check rounding. The most significant digit is under 5 *)
  fun fmt_SCI_normal_0021 () =
      let
        val case_SCI_0004_N_n3 as () = test (SCI NONE) 0.004 "4.000000E~3"
        val case_SCI_0004_0_n3 as () = test (SCI (SOME 0)) 0.004 "4E~3"
        val case_SCI_0004_1_n3 as () = test (SCI (SOME 1)) 0.004 "4.0E~3"
        val case_SCI_0004_2_n3 as () = test (SCI (SOME 2)) 0.004 "4.00E~3"
        val case_SCI_0004_3_n3 as () = test (SCI (SOME 3)) 0.004 "4.000E~3"
        val case_SCI_0004_4_n3 as () = test (SCI (SOME 4)) 0.004 "4.0000E~3"
      in () end
  (* check rounding. The most significant digit is over 5 *)
  fun fmt_SCI_normal_0022 () =
      let
        val case_SCI_0006_N_n3 as () = test (SCI NONE) 0.006 "6.000000E~3"
        val case_SCI_0006_0_n3 as () = test (SCI (SOME 0)) 0.006 "6E~3"
        val case_SCI_0006_1_n3 as () = test (SCI (SOME 1)) 0.006 "6.0E~3"
        val case_SCI_0006_2_n3 as () = test (SCI (SOME 2)) 0.006 "6.00E~3"
        val case_SCI_0006_3_n3 as () = test (SCI (SOME 3)) 0.006 "6.000E~3"
        val case_SCI_0006_4_n3 as () = test (SCI (SOME 4)) 0.006 "6.0000E~3"
      in () end
  (* check sign *)
  fun fmt_SCI_normal_0023 () =
      let
        val case_SCI_n0001_N_n3 as () = test (SCI NONE) ~0.001 "~1.000000E~3"
        val case_SCI_n0001_0_n3 as () = test (SCI (SOME 0)) ~0.001 "~1E~3"
        val case_SCI_n0001_1_n3 as () = test (SCI (SOME 1)) ~0.001 "~1.0E~3"
        val case_SCI_n0001_2_n3 as () = test (SCI (SOME 2)) ~0.001 "~1.00E~3"
        val case_SCI_n0001_3_n3 as () = test (SCI (SOME 3)) ~0.001 "~1.000E~3"
        val case_SCI_n0001_4_n3 as () = test (SCI (SOME 4)) ~0.001 "~1.0000E~3"
      in () end
  fun fmt_SCI_abnormal () =
      let
        val case_SCI_p0_N as () = test (SCI NONE) pos0 "0.000000E0"
        val case_SCI_p0_0 as () = test (SCI (SOME 0)) pos0 "0E0"
        val case_SCI_p0_1 as () = test (SCI (SOME 1)) pos0 "0.0E0"
        val case_SCI_n0_N as () = test (SCI NONE) neg0 "~0.000000E0"
        val case_SCI_n0_0 as () = test (SCI (SOME 0)) neg0 "~0E0"
        val case_SCI_n0_1 as () = test (SCI (SOME 1)) neg0 "~0.0E0"
        val case_SCI_pinf_N as () = test (SCI NONE) posInf "inf"
        val case_SCI_ninf_N as () = test (SCI NONE) negInf "~inf"
        (* sign of nan is ignored. *)
        val case_SCI_pnan_N as () = test (SCI NONE) posNan "nan"
        val case_SCI_nnan_N as () = test (SCI NONE) negNan "nan"
      in () end

  fun fmt_FIX_normal_0001 () =
      let
(*
        val case_FIX_1875_N_1 as () = test (FIX NONE) 18.75 "18.750000"
        val case_FIX_1875_0_1 as () = test (FIX (SOME 0)) 18.75 "18"
        val case_FIX_1875_1_1 as () = test (FIX (SOME 1)) 18.75 "18.7"
        val case_FIX_1875_2_1 as () = test (FIX (SOME 2)) 18.75 "18.75"
        val case_FIX_1875_3_1 as () = test (FIX (SOME 3)) 18.75 "18.750"
        val case_FIX_1875_4_1 as () = test (FIX (SOME 4)) 18.75 "18.7500"
        val case_FIX_1875_N_0 as () = test (FIX NONE) 1.875 "1.875000"
        val case_FIX_1875_N_n1 as () = test (FIX NONE) 0.1875 "0.187500"
*)
        val case_FIX_1875_N_1 as () = test (FIX NONE) 18.75 "18.750000"
        val case_FIX_1875_0_1 as () = test (FIX (SOME 0)) 18.75 "19"
        val case_FIX_1875_1_1 as () = test (FIX (SOME 1)) 18.75 "18.8"
        val case_FIX_1875_2_1 as () = test (FIX (SOME 2)) 18.75 "18.75"
        val case_FIX_1875_3_1 as () = test (FIX (SOME 3)) 18.75 "18.750"
        val case_FIX_1875_4_1 as () = test (FIX (SOME 4)) 18.75 "18.7500"
        val case_FIX_1875_N_0 as () = test (FIX NONE) 1.875 "1.875000"
        val case_FIX_1875_N_n1 as () = test (FIX NONE) 0.1875 "0.187500"
        val case_FIX_n1875_N_1 as () = test (FIX NONE) ~18.75 "~18.750000"
      in () end
  (* check exponential. The real is just on power of 10. *)
  fun fmt_FIX_normal_0010 () =
      let
        val case_FIX_100_N_1 as () = test (FIX NONE) 10.0 "10.000000"
        val case_FIX_100_0_1 as () = test (FIX (SOME 0)) 10.0 "10"
        val case_FIX_100_1_1 as () = test (FIX (SOME 1)) 10.0 "10.0"
        val case_FIX_100_2_1 as () = test (FIX (SOME 2)) 10.0 "10.00"
        val case_FIX_100_3_1 as () = test (FIX (SOME 3)) 10.0 "10.000"
      in () end
  (* check rounding. The most significant digit is under 5 *)
  fun fmt_FIX_normal_0011 () =
      let
        val case_FIX_400_N_1 as () = test (FIX NONE) 40.0 "40.000000"
        val case_FIX_400_0_1 as () = test (FIX (SOME 0)) 40.0 "40"
        val case_FIX_400_1_1 as () = test (FIX (SOME 1)) 40.0 "40.0"
        val case_FIX_400_2_1 as () = test (FIX (SOME 2)) 40.0 "40.00"
        val case_FIX_400_3_1 as () = test (FIX (SOME 3)) 40.0 "40.000"
      in () end
  (* check rounding. The most significant digit is over 5 *)
  fun fmt_FIX_normal_0012 () =
      let
        val case_FIX_600_N_1 as () = test (FIX NONE) 60.0 "60.000000"
        val case_FIX_600_0_1 as () = test (FIX (SOME 0)) 60.0 "60"
        val case_FIX_600_1_1 as () = test (FIX (SOME 1)) 60.0 "60.0"
        val case_FIX_600_2_1 as () = test (FIX (SOME 2)) 60.0 "60.00"
        val case_FIX_600_3_1 as () = test (FIX (SOME 3)) 60.0 "60.000"
      in () end
  (* check sign. *)
  fun fmt_FIX_normal_0013 () =
      let
        val case_FIX_n100_N_1 as () = test (FIX NONE) ~10.0 "~10.000000"
        val case_FIX_n100_0_1 as () = test (FIX (SOME 0)) ~10.0 "~10"
        val case_FIX_n100_1_1 as () = test (FIX (SOME 1)) ~10.0 "~10.0"
        val case_FIX_n100_2_1 as () = test (FIX (SOME 2)) ~10.0 "~10.00"
        val case_FIX_n100_3_1 as () = test (FIX (SOME 3)) ~10.0 "~10.000"
      in () end
  (* check exponential. The real is just on power of 10. *)
  fun fmt_FIX_normal_0020 () =
      let
        val case_FIX_0001_N_n3 as () = test (FIX NONE) 0.001 "0.001000"
        val case_FIX_0001_0_n3 as () = test (FIX (SOME 0)) 0.001 "0"
        val case_FIX_0001_1_n3 as () = test (FIX (SOME 1)) 0.001 "0.0"
        val case_FIX_0001_2_n3 as () = test (FIX (SOME 2)) 0.001 "0.00"
        val case_FIX_0001_3_n3 as () = test (FIX (SOME 3)) 0.001 "0.001"
        val case_FIX_0001_4_n3 as () = test (FIX (SOME 4)) 0.001 "0.0010"
      in () end
  (* check exponential. The most significant digit is under 5 *)
  fun fmt_FIX_normal_0021 () =
      let
        val case_FIX_0004_N_n3 as () = test (FIX NONE) 0.004 "0.004000"
        val case_FIX_0004_0_n3 as () = test (FIX (SOME 0)) 0.004 "0"
        val case_FIX_0004_1_n3 as () = test (FIX (SOME 1)) 0.004 "0.0"
        val case_FIX_0004_2_n3 as () = test (FIX (SOME 2)) 0.004 "0.00"
        val case_FIX_0004_3_n3 as () = test (FIX (SOME 3)) 0.004 "0.004"
        val case_FIX_0004_4_n3 as () = test (FIX (SOME 4)) 0.004 "0.0040"
      in () end
  (* check exponential. The most significant digit is over 5 *)
  fun fmt_FIX_normal_0022 () =
      let
(*
        val case_FIX_0006_N_n3 as () = test (FIX NONE) 0.006 "0.006000"
        val case_FIX_0006_0_n3 as () = test (FIX (SOME 0)) 0.006 "0"
        val case_FIX_0006_1_n3 as () = test (FIX (SOME 1)) 0.006 "0.0"
        val case_FIX_0006_2_n3 as () = test (FIX (SOME 2)) 0.006 "0.00"
        val case_FIX_0006_3_n3 as () = test (FIX (SOME 3)) 0.006 "0.006"
        val case_FIX_0006_4_n3 as () = test (FIX (SOME 4)) 0.006 "0.0060"
*)
        val case_FIX_0006_N_n3 as () = test (FIX NONE) 0.006 "0.006000"
        val case_FIX_0006_0_n3 as () = test (FIX (SOME 0)) 0.006 "0"
        val case_FIX_0006_1_n3 as () = test (FIX (SOME 1)) 0.006 "0.0"
        val case_FIX_0006_2_n3 as () = test (FIX (SOME 2)) 0.006 "0.01"
        val case_FIX_0006_3_n3 as () = test (FIX (SOME 3)) 0.006 "0.006"
        val case_FIX_0006_4_n3 as () = test (FIX (SOME 4)) 0.006 "0.0060"
      in () end
  (* check sign. *)
  fun fmt_FIX_normal_0023 () =
      let
        val case_FIX_n0001_N_n3 as () = test (FIX NONE) ~0.001 "~0.001000"
        val case_FIX_n0001_0_n3 as () = test (FIX (SOME 0)) ~0.001 "~0"
        val case_FIX_n0001_1_n3 as () = test (FIX (SOME 1)) ~0.001 "~0.0"
        val case_FIX_n0001_2_n3 as () = test (FIX (SOME 2)) ~0.001 "~0.00"
        val case_FIX_n0001_3_n3 as () = test (FIX (SOME 3)) ~0.001 "~0.001"
        val case_FIX_n0001_4_n3 as () = test (FIX (SOME 4)) ~0.001 "~0.0010"
      in () end
  fun fmt_FIX_abnormal () =
      let
        val case_FIX_p0_N as () = test (FIX NONE) pos0 "0.000000"
        val case_FIX_p0_0 as () = test (FIX (SOME 0)) pos0 "0"
        val case_FIX_p0_1 as () = test (FIX (SOME 1)) pos0 "0.0"
        val case_FIX_n0_N as () = test (FIX NONE) neg0 "~0.000000"
        val case_FIX_n0_0 as () = test (FIX (SOME 0)) neg0 "~0"
        val case_FIX_n0_1 as () = test (FIX (SOME 1)) neg0 "~0.0"
        val case_FIX_pinf_N as () = test (FIX NONE) posInf "inf"
        val case_FIX_ninf_N as () = test (FIX NONE) negInf "~inf"
        val case_FIX_pnan_N as () = test (FIX NONE) posNan "nan"
        val case_FIX_nnan_N as () = test (FIX NONE) negNan "nan"
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
        val case_GEN_p_N_11 as () =
            test (GEN NONE) 1234567890100000.0 "1.2345678901E15" (* SCI *)
        (*
         * FIX: 1234567890120000
         * SCI: 1.23456789012E15
         * Both are the same length. FIX should be selected.
         *)
        val case_GEN_p_N_12 as () =
            test (GEN NONE) 1234567890120000.0 "1234567890120000" (* FIX *)
        val case_GEN_p_N_13 as () =
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
        val case_GEN_p_N_n3_11 as () =
            test (GEN NONE) 0.0012345678901 "0.0012345678901" (* FIX *)
        (*
         * FIX: 0.00012345678901
         * SCI: 1.2345678901E~4
         *)
        val case_GEN_p_N_n4_11 as () =
            test (GEN NONE) 0.00012345678901 "1.2345678901E~4" (* SCI *)
        (*
         * FIX: 0.000123456789012
         * SCI: 1.23456789012E~4
         *)
        val case_GEN_p_N__n4_12 as () =
            test (GEN NONE) 0.000123456789012 "1.23456789012E~4" (* SCI *)
        val case_GEN_p_N__n4_13 as () =
            test (GEN NONE) 0.0001234567890123 "1.23456789012E~4" (* SCI *)
      in () end
  fun fmt_GEN_normal_SOME_posExp () =
      let
        (* shorter format of SCI or FIX should be selected. *)

        (* GEN (SOME(0)) is error *)

        (* SCI: 1E4
         * FIX: 10000 *)
        val case_GEN_p_1_4 as () = test (GEN (SOME 1)) 13500.13 "1E4" (* SCI *)
        (* SCI: 1.3E4
         * FIX: 13000 *)
        val case_GEN_p_2_4 as () = test (GEN (SOME 2)) 13500.13 "13000" (* FIX *)
        (* SCI: 1.35E4
         * FIX: 13500 *)
        val case_GEN_p_3_4 as () = test (GEN (SOME 3)) 13500.13 "13500" (* FIX *)
      in () end
  fun fmt_GEN_normal_SOME_negExp () =
      let
        (* negative Exp *)

        (* SCI: 1.23E~2
         * FIX: 0.0123 *)
        val case_GEN_n_n2_3 as () = test (GEN (SOME 3)) 0.01234 "0.0123"
        (* SCI: 1.23E~3
         * FIX: 0.00123 *)
        val case_GEN_p_n3_3 as () = test (GEN (SOME 3)) 0.001234 "0.00123"
        (* SCI: 1.23E~4
         * FIX: 0.000123 *)
        val case_GEN_p_n4_3 as () = test (GEN (SOME 3)) 0.0001234 "1.23E~4"
      in () end
  fun fmt_GEN_abnormal () =
      let
        val case_GEN_p0_N as () = test (GEN NONE) pos0 "0"
        val case_GEN_p0_1 as () = test (GEN (SOME 1)) pos0 "0"
        val case_GEN_n0_N as () = test (GEN NONE) neg0 "~0"
        val case_GEN_n0_1 as () = test (GEN (SOME 1)) neg0 "~0"
        val case_GEN_pinf_N as () = test (GEN NONE) posInf "inf"
        val case_GEN_ninf_N as () = test (GEN NONE) negInf "~inf"
        val case_GEN_pnan_N as () = test (GEN NONE) posNan "nan"
        val case_GEN_nnan_N as () = test (GEN NONE) negNan "nan"
      in () end

  fun fmt_error () =
      let
        val case_SCI as () =
            (R.fmt (SCI (SOME ~1)); fail "frm SCI(~1) should raise Size.")
            handle General.Size => ()
        val case_FIX as () =
            (R.fmt (FIX (SOME ~1)); fail "frm FIX(~1) should raise Size.")
            handle General.Size => ()
        val case_GEN as () =
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
        val case_n2 as () = test 0.01234567890123 "0.0123456789012"
        val case_n3 as () = test 0.001234567890123 "0.00123456789012"
        val case_n4 as () = test 0.0001234567890123 "1.23456789012E~4"

        val case_14 as () = test 123456789012300.0 "123456789012000"
        val case_15 as () = test 1234567890123000.0 "1234567890120000"
        val case_16 as () = test 12345678901230000.0 "1.23456789012E16"
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
        val case_N_123_N_N_N as () = test "123" (SOME(123.0, ""))
        val case_N_123_456_N_N as () = test "123.456" (SOME(123.456, ""))
        val case_N_123_456_N_1 as () = test "123.456E1" (SOME(1234.56, ""))

        val case_p_123_N_N_N as () = test "+123" (SOME(123.0, ""))
        val case_t_123_N_N_N as () = test "~123" (SOME(~123.0, ""))
        val case_m_123_N_N_N as () = test "-123" (SOME(~123.0, ""))
        val case_m_123_456_N_1 as () = test "-123.456E1" (SOME(~1234.56, ""))
        val case_m_123_456_m_1 as () = test "-123.456E-1" (SOME(~12.3456, ""))
      in () end
  fun scan_normal_0002 () =
      let
        (* test case for numbers with no whole part *)
        val case_N_N_123_N_1 as () = test ".123E1" (SOME(1.23, ""))
        val case_N_N_123_N_10 as () = test ".123E10" (SOME(1230000000.0, ""))
        val case_N_N_123_p_1 as () = test ".123E+1" (SOME(1.23, ""))
        val case_N_N_123_t_1 as () = test ".123E~1" (SOME(0.0123, ""))
        val case_N_N_123_m_1 as () = test ".123E-1" (SOME(0.0123, ""))
        val case_N_N_123_m_10 as () = test ".123E-10" (SOME(0.0000000000123, ""))
      in () end
  fun scan_normal_0003 () =
      let
        (* test case for zero. *)
        val case_N_N_0_N_N as () = test ".0E1" (SOME(0.0, ""))
        val case_N_0_N_N_N as () = test "0E1" (SOME(0.0, ""))
        val case_N_0_0_N_N as () = test "0.0E1" (SOME(0.0, ""))
        val case_p_0_0_N_N as () = test "0.0E1" (SOME(pos0, ""))
        val case_t_0_0_N_N as () = test "~0.0E1" (SOME(neg0, ""))
        val case_m_0_0_N_N as () = test "-0.0E1" (SOME(neg0, ""))
      in () end
  fun scan_normal_0010 () =
      let
        (* test case for initial whitespaces and trailer *)
        val case_initws as () = test " \n\r\t\v\f123.456" (SOME(123.456, ""))
        val case_trail_1 as () = test "123.456ABC" (SOME(123.456, "ABC"))
        val case_trail_2 as () = test "123.456.123" (SOME(123.456, ".123"))
      in () end
  fun scan_normal_0011 () =
      let
        (* test case for case insensitive *)
        val case_smallE as () = test "123.456e1" (SOME(1234.56, ""))
        val case_largeE as () = test "123.456E1" (SOME(1234.56, ""))
      in () end
  fun scan_normal_0012 () =
      let
        (* test case for extremes. *)
        val case_error_Ebig as () = test "1E1000" (SOME(posInf, ""))
      in () end
  fun scan_normal_1001 () =
      let
        (* test cases for bugs? in the format specified in Basis spec. *)
        (* With whole part and 'E', but no exponential part. *)
        val case_error_E1 as () = test "1EA" (SOME(1.0, "A"))
        (* With 'E' and exponential, but no whole part. *)
        val case_error_E2 as () = test "E1" NONE
        (* Only 'E' *)
        val case_error_E3 as () = test "E" NONE
        (* With decimal point, but no fractional part. *)
        val case_error_dot as () = test "1..1" (SOME(1.0, ".1"))
      in () end

  (* The valid format of Real.scan for abnormal floats is:
   * [+~-]?(inf | infinity | nan)
   *)
  fun scan_abnormal_0001 () =
      let
        val case_N_inf as () = test "inf" (SOME(posInf, ""))
        val case_N_infinity as () = test "infinity" (SOME(posInf, ""))
        val case_N_nan as () = test "nan" (SOME(posNan, ""))

        val case_p_inf as () = test "+inf" (SOME(posInf, ""))
        val case_p_infinity as () = test "+infinity" (SOME(posInf, ""))
        val case_p_nan as () = test "+nan" (SOME(posNan, ""))

        val case_t_inf as () = test "~inf" (SOME(negInf, ""))
        val case_t_infinity as () = test "~infinity" (SOME(negInf, ""))
        val case_t_nan as () = test "~nan" (SOME(negNan, ""))
      in () end
  fun scan_abnormal_0002 () =
      let
        (* test case for case insensitive *)
        val case_INF as () = test "INF" (SOME(posInf, ""))
        val case_INFINITY as () = test "INFINITY" (SOME(posInf, ""))
        val case_NAN as () = test "NAN" (SOME(posNan, ""))
      in () end
  fun scan_abnormal_0010 () =
      let
        (* test case for initial whitespace and trailer *)
        val case_initws_inf as () = test " \n\r\t\v\finf" (SOME(posInf, ""))
        val case_initws_infinity as () = test " \n\r\t\v\finfinity" (SOME(posInf, ""))
        val case_initws_nan as () = test " \n\r\t\v\fnan" (SOME(posNan, ""))

        val case_trail_inf_1 as () = test "infABC" (SOME(posInf, "ABC"))
        val case_trail_inf_2 as () = test "infinit" (SOME(posInf, "init"))
        val case_trail_infinity as () = test "infinityABC" (SOME(posInf, "ABC"))
        val case_trail_nan as () = test "nanABC" (SOME(posNan, "ABC"))
      in () end
  end (* local *)

  (**********)

  fun fromString0001 () =
      let
        val fromString_1 = R.fromString "123.456E10"
        val () = assertEqualRealOption (SOME(1234560000000.0)) fromString_1

        val fromString_2 = R.fromString "ABC"
        val () = assertEqualRealOption NONE fromString_2
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
        val case_p_p as () = test 12.5 (IR.NORMAL, false, [1, 2, 5], 2)
        val case_p_0 as () = test 0.125 (IR.NORMAL, false, [1, 2, 5], 0)
        val case_p_n as () = test 0.015625 (IR.NORMAL, false, [1, 5, 6, 2, 5], ~1)

        val case_n_p as () = test ~12.5 (IR.NORMAL, true, [1, 2, 5], 2)
        val case_n_0 as () = test ~0.125 (IR.NORMAL, true, [1, 2, 5], 0)
        val case_n_n as () = test ~0.015625 (IR.NORMAL, true, [1, 5, 6, 2, 5], ~1)
      in () end
  fun toDecimal_abnormal_0001 () =
      let
        val case_p0 as () = test pos0 (IR.ZERO, false, [], 0)
        val case_n0 as () = test neg0 (IR.ZERO, true, [], 0)
        val case_pinf as () = test posInf (IR.INF, false, [], 0)
        val case_ninf as () = test negInf (IR.INF, true, [], 0)

        val case_pnan as () = test posNan (IR.NAN, false, [], 0)
        val case_nnan as () = test negNan (IR.NAN, true, [], 0)
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
        val case_p_p as () = test (IR.NORMAL, false, [1, 2, 5], 2) (SOME 12.5)
        val case_p_0 as () = test (IR.NORMAL, false, [1, 2, 5], 0) (SOME 0.125)
        val case_p_n as () = test (IR.NORMAL, false, [1, 2, 5], ~2) (SOME 0.00125)

        val case_n_p as () = test (IR.NORMAL, true, [1, 2, 5], 2) (SOME ~12.5)
        val case_n_0 as () = test (IR.NORMAL, true, [1, 2, 5], 0) (SOME ~0.125)
        val case_n_n as () = test (IR.NORMAL, true, [1, 2, 5], ~2) (SOME ~0.00125)
      in () end
  (* fromDecimal should ignore class field for IR.NORMAL. *)
  fun fromDecimal_normal_0002 () =
      let
        (* empty digits *)
        val case_NORMAL_p0 as () = test (IR.NORMAL, false, [], 2) (SOME pos0)
        (* very large magnitude *)
        val case_NORMAL_pinf as () = test (IR.NORMAL, false, [1], 1000) (SOME posInf)
        val case_NORMAL_ninf as () = test (IR.NORMAL, true, [1], 1000) (SOME negInf)
        (* very small magnitude *)
        val case_NORMAL_p0 as () = test (IR.NORMAL, false, [1], ~1000) (SOME pos0)
        val case_NORMAL_n0 as () = test (IR.NORMAL, true, [1], ~1000) (SOME neg0)
      in () end
  (* error case *)
  fun fromDecimal_normal_1001 () =
      let
        val case_invalid_digits as () = test (IR.NORMAL, false, [10], 0) NONE
      in () end

  (* safe case *)
  fun fromDecimal_abnormal_0001 () =
      let
        val case_p0 as () = test (IR.ZERO, false, [], 0) (SOME pos0)
        val case_n0 as () = test (IR.ZERO, true, [], 0) (SOME neg0)

        val case_pinf as () = test (IR.INF, false, [], 0) (SOME posInf)
        val case_ninf as () = test (IR.INF, true, [], 0) (SOME negInf)

        val case_pnan as () = test (IR.NAN, false, [], 0) (SOME posNan)
        val case_nnan as () = test (IR.NAN, true, [], 0) (SOME negNan)
      in () end
  fun fromDecimal_abnormal_0002 () =
      let
        (* digits and exp are ignored *)
        val case_INF_p as () = test (IR.INF, false, [1, 2, 3], 2) (SOME posInf)
        val case_NAN_p as () = test (IR.NAN, false, [1, 2, 3], 2) (SOME posNan)
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
