(**
 * test cases for IEEEReal structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure IEEEReal001 =
struct

  (************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test
  structure AI = AssertIEEEReal
  open A
  open AI

  structure R = IEEEReal

  (************************************************************)

  fun makeDec (class, sign, digits, exp) =
      {class = class, sign = sign, digits = digits, exp = exp}
      : R.decimal_approx

  val assertEqualDecOption = assertEqualOption assertEqualDecimalApprox

  (********************)

  fun roundingMode001 () =
      let
        val _ = R.setRoundingMode R.TO_NEAREST
        val _ = assertEqualRoundingMode
                    R.TO_NEAREST (R.getRoundingMode())

        val _ = R.setRoundingMode R.TO_NEGINF
        val _ = assertEqualRoundingMode
                    R.TO_NEGINF (R.getRoundingMode ())

        val _ = R.setRoundingMode R.TO_POSINF
        val _ = assertEqualRoundingMode
                    R.TO_POSINF (R.getRoundingMode ())

        val _ = R.setRoundingMode R.TO_ZERO
        val _ = assertEqualRoundingMode
                    R.TO_ZERO (R.getRoundingMode ())
      in () end

  (********************)

  local
    fun test arg expected =
        assertEqualString expected (R.toString (makeDec arg))
  in
  fun toString001 () =
      let
        val toString_NAN = test (R.NAN, false, [], 0) "nan" 
        val toString_POS_INF = test (R.INF, false, [], 0) "inf" 
        val toString_NEG_INF = test (R.INF, true, [], 0) "~inf" 
        val toString_POS_ZERO = test (R.ZERO, false, [], 0) "0.0" 
        val toString_NEG_ZERO = test (R.ZERO, true, [], 0) "~0.0" 
        (**********)
        val toString_NORMAL_P_0_0 = test (R.NORMAL, false, [0], 0) "0.0" 
        val toString_NORMAL_P_1_0 = test (R.NORMAL, false, [1], 0) "0.1" 
        val toString_NORMAL_P_1_1 = test (R.NORMAL, false, [1], 1) "0.1E1" 
        val toString_NORMAL_P_1_2 = test (R.NORMAL, false, [1], 2) "0.1E2" 
        val toString_NORMAL_P_1_m1 = test (R.NORMAL, false, [1], ~1) "0.1E~1" 
        val toString_NORMAL_P_1_m2 = test (R.NORMAL, false, [1], ~2) "0.1E~2" 
        val toString_NORMAL_P_2_0 = test (R.NORMAL, false, [1, 2], 0) "0.12" 
        val toString_NORMAL_P_2_1 = test (R.NORMAL, false, [1, 2], 1) "0.12E1" 
        val toString_NORMAL_P_2_2 = test (R.NORMAL, false, [1, 2], 2) "0.12E2" 
        val toString_NORMAL_P_2_3 = test (R.NORMAL, false, [1, 2], 3) "0.12E3" 
        val toString_NORMAL_P_2_m1 = test (R.NORMAL, false, [1, 2], ~1) "0.12E~1" 
        val toString_NORMAL_P_2_m2 = test (R.NORMAL, false, [1, 2], ~2) "0.12E~2" 
        val toString_NORMAL_P_2_m3 = test (R.NORMAL, false, [1, 2], ~3) "0.12E~3" 
        (**********)
        val toString_NORMAL_N_0_0 = test (R.NORMAL, true, [0], 0) "~0.0" 
        val toString_NORMAL_N_1_0 = test (R.NORMAL, true, [1], 0) "~0.1" 
        val toString_NORMAL_N_1_1 = test (R.NORMAL, true, [1], 1) "~0.1E1" 
        val toString_NORMAL_N_1_2 = test (R.NORMAL, true, [1], 2) "~0.1E2" 
        val toString_NORMAL_N_1_m1 = test (R.NORMAL, true, [1], ~1) "~0.1E~1" 
        val toString_NORMAL_N_1_m2 = test (R.NORMAL, true, [1], ~2) "~0.1E~2" 
        val toString_NORMAL_N_2_0 = test (R.NORMAL, true, [1, 2], 0) "~0.12" 
        val toString_NORMAL_N_2_1 = test (R.NORMAL, true, [1, 2], 1) "~0.12E1" 
        val toString_NORMAL_N_2_2 = test (R.NORMAL, true, [1, 2], 2) "~0.12E2" 
        val toString_NORMAL_N_2_3 = test (R.NORMAL, true, [1, 2], 3) "~0.12E3" 
        val toString_NORMAL_N_2_m1 = test (R.NORMAL, true, [1, 2], ~1) "~0.12E~1" 
        val toString_NORMAL_N_2_m2 = test (R.NORMAL, true, [1, 2], ~2) "~0.12E~2" 
        val toString_NORMAL_N_2_m3 = test (R.NORMAL, true, [1, 2], ~3) "~0.12E~3" 
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected =
        assertEqualDecOption (SOME (makeDec expected)) (R.fromString arg)
  in

  fun fromString_inf () =
      let
        val fromString_n_inf = test "inf" (R.INF, false, [], 0)
        val fromString_p_inf = test "+inf" (R.INF, false, [], 0)
        val fromString_m_inf = test "-inf" (R.INF, true, [], 0)
        val fromString_t_inf = test "~inf" (R.INF, true, [], 0)
        val fromString_upper_inf = test "INF" (R.INF, false, [], 0)
      in () end

  fun fromString_infinity () =
      let
        val fromString_n_infinity = test "infinity" (R.INF, false, [], 0)
        val fromString_p_infinity = test "+infinity" (R.INF, false, [], 0)
        val fromString_m_infinity = test "-infinity" (R.INF, true, [], 0)
        val fromString_t_infinity = test "~infinity" (R.INF, true, [], 0)
        val fromString_upper_infinity = test "INFINITY" (R.INF, false, [], 0)
      in () end

  fun fromString_nan () =
      let
        val fromString_n_nan = test "nan" (R.NAN, false, [], 0)
        val fromString_p_nan = test "+nan" (R.NAN, false, [], 0)
        val fromString_m_nan = test "-nan" (R.NAN, true, [], 0)
        val fromString_t_nan = test "~nan" (R.NAN, true, [], 0)
        val fromString_upper_nan = test "NAN" (R.NAN, false, [], 0)
      in () end

  (* The fromString must parse the following regular expression.
   * [+~-]?([0-9]+.[0-9]+? | .[0-9]+)(e | E)[+~-]?[0-9]+? 
   *)

  fun fromString_integer () =
      let
        (* test of integer part
         * [+~-]?[0-9]+.(e|E) 
         *)
        val fromString_n_0e = test "0.e" (R.ZERO, false, [], 0)
        val fromString_n_0E = test "0.E" (R.ZERO, false, [], 0)
        val fromString_01 = test "01." (R.NORMAL, false, [1], 1)
        val fromString_012 = test "012." (R.NORMAL, false, [1, 2], 2)
      in () end

  fun fromString_fraction () =
      let
        (* test of fraction part
         * [+~-]?.[0-9]+(e|E)
         *)
        val fromString_0 = test ".0e0" (R.ZERO, false, [], 0)
        val fromString_1 = test ".1e" (R.NORMAL, false, [1], 0)
        val fromString_0120 = test ".0120e" (R.NORMAL, false, [1, 2], ~1)
      in () end

  fun fromString_integer_fraction () =
      let
        (* test of integer+fraction part
         * [+~-]?[0-9]+.[0-9]+(e|E) 
         *)
        val fromString_0_0 = test "0.0e" (R.ZERO, false, [], 0)
        val fromString_0_1 = test "0.1e" (R.NORMAL, false, [1], 0)
        val fromString_1_0 = test "1.0e" (R.NORMAL, false, [1], 1)
        val fromString_0_0120 = test "0.0120e" (R.NORMAL, false, [1, 2], ~1)
        val fromString_0120_0 = test "0120.0e" (R.NORMAL, false, [1, 2], 3)
        val fromString_0120_0120 = test "0120.0120e" (R.NORMAL, false, [1, 2, 0, 0, 1, 2], 3)
      in () end

  fun fromString_exp () =
      let
        (* test of exp part
         * [+~-]?[0-9]+.[0-9]+(e|E)[+~-]?[0-9]+ 
         *)
        val fromString_0_0_0 = test "0.0e0" (R.ZERO, false, [], 0)
        val fromString_0120_0120_1 = test "0120.0120e1" (R.NORMAL, false, [1, 2, 0, 0, 1, 2], 4)
        val fromString_0120_0120_p1 = test "0120.0120e+1" (R.NORMAL, false, [1, 2, 0, 0, 1, 2], 4)
        val fromString_0120_0120_m1 = test "0120.0120e-1" (R.NORMAL, false, [1, 2, 0, 0, 1, 2], 2)
        val fromString_0120_0120_t1 = test "0120.0120e~1" (R.NORMAL, false, [1, 2, 0, 0, 1, 2], 2)
      in () end

  fun fromString_sign () =
      let
        (* test of sign part
         *)
        val fromString_p_0 = test "+0.E" (R.ZERO, false, [], 0)
        val fromString_m_0 = test "-0.E" (R.ZERO, true, [], 0)
        val fromString_t_0 = test "~0.E" (R.ZERO, true, [], 0)
        val fromString_p_0120_0120_t1 = test "+0120.0120e~1" (R.NORMAL, false, [1, 2, 0, 0, 1, 2], 2)
        val fromString_m_0120_0120_t1 = test "-0120.0120e~1" (R.NORMAL, true, [1, 2, 0, 0, 1, 2], 2)
        val fromString_t_0120_0120_t1 = test "~0120.0120e~1" (R.NORMAL, true, [1, 2, 0, 0, 1, 2], 2)
      in () end

  fun fromString_header_trailer () =
      let
        (* test of leading white spaces and trailers
         *)
        val fromString_ws_p_0120_0120_t1 = test "  +0120.0120e~1abc" (R.NORMAL, false, [1, 2, 0, 0, 1, 2], 2)
      in () end

  fun fromString_invalid1 () =
      let
        val fromString_nodot = R.fromString "123"
        val _ = assertNone fromString_nodot

        val fromString_alpha = R.fromString "A"
        val _ = assertNone fromString_alpha

        val fromString_onlyE = R.fromString "E"
        val _ = assertNone fromString_onlyE
      in () end

  end (* local *)

  (****************************************)

  fun suite () =
      T.labelTests
      [
        ("roundingMode001", roundingMode001),
        ("toString001", toString001),
        ("fromString_inf", fromString_inf),
        ("fromString_infinity", fromString_infinity),
        ("fromString_nan", fromString_nan),
        ("fromString_integer", fromString_integer),
        ("fromString_fraction", fromString_fraction),
        ("fromString_integer_fraction", fromString_integer_fraction),
        ("fromString_exp", fromString_exp),
        ("fromString_sign", fromString_sign),
        ("fromString_header_trailer", fromString_header_trailer),
        ("fromString_invalid1", fromString_invalid1)
      ]

  (************************************************************)

end