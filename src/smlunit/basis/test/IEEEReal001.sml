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
  structure AI = SMLUnit.Assert.AssertIEEEReal
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
        val () = R.setRoundingMode R.TO_NEAREST
        val () = assertEqualRoundingMode
                    R.TO_NEAREST (R.getRoundingMode())

        val () = R.setRoundingMode R.TO_NEGINF
        val () = assertEqualRoundingMode
                    R.TO_NEGINF (R.getRoundingMode ())

        val () = R.setRoundingMode R.TO_POSINF
        val () = assertEqualRoundingMode
                    R.TO_POSINF (R.getRoundingMode ())

        val () = R.setRoundingMode R.TO_ZERO
        val () = assertEqualRoundingMode
                    R.TO_ZERO (R.getRoundingMode ())
      in () end

  (********************)

  local
    fun test arg expected =
        assertEqualString expected (R.toString (makeDec arg))
  in
  fun toString001 () =
      let
(*
        val case_NAN as () = test (R.NAN, false, [], 0) "nan" 
*)
        val case_POS_INF as () = test (R.INF, false, [], 0) "inf" 
        val case_NEG_INF as () = test (R.INF, true, [], 0) "~inf" 
        val case_POS_ZERO as () = test (R.ZERO, false, [], 0) "0.0" 
        val case_NEG_ZERO as () = test (R.ZERO, true, [], 0) "~0.0" 
        (**********)
        val case_NORMAL_P_0_0 as () = test (R.NORMAL, false, [0], 0) "0.0" 
        val case_NORMAL_P_1_0 as () = test (R.NORMAL, false, [1], 0) "0.1" 
        val case_NORMAL_P_1_1 as () = test (R.NORMAL, false, [1], 1) "0.1E1" 
        val case_NORMAL_P_1_2 as () = test (R.NORMAL, false, [1], 2) "0.1E2" 
        val case_NORMAL_P_1_m1 as () = test (R.NORMAL, false, [1], ~1) "0.1E~1" 
        val case_NORMAL_P_1_m2 as () = test (R.NORMAL, false, [1], ~2) "0.1E~2" 
        val case_NORMAL_P_2_0 as () = test (R.NORMAL, false, [1, 2], 0) "0.12" 
        val case_NORMAL_P_2_1 as () = test (R.NORMAL, false, [1, 2], 1) "0.12E1" 
        val case_NORMAL_P_2_2 as () = test (R.NORMAL, false, [1, 2], 2) "0.12E2" 
        val case_NORMAL_P_2_3 as () = test (R.NORMAL, false, [1, 2], 3) "0.12E3" 
        val case_NORMAL_P_2_m1 as () = test (R.NORMAL, false, [1, 2], ~1) "0.12E~1" 
        val case_NORMAL_P_2_m2 as () = test (R.NORMAL, false, [1, 2], ~2) "0.12E~2" 
        val case_NORMAL_P_2_m3 as () = test (R.NORMAL, false, [1, 2], ~3) "0.12E~3" 
        (**********)
        val case_NORMAL_N_0_0 as () = test (R.NORMAL, true, [0], 0) "~0.0" 
        val case_NORMAL_N_1_0 as () = test (R.NORMAL, true, [1], 0) "~0.1" 
        val case_NORMAL_N_1_1 as () = test (R.NORMAL, true, [1], 1) "~0.1E1" 
        val case_NORMAL_N_1_2 as () = test (R.NORMAL, true, [1], 2) "~0.1E2" 
        val case_NORMAL_N_1_m1 as () = test (R.NORMAL, true, [1], ~1) "~0.1E~1" 
        val case_NORMAL_N_1_m2 as () = test (R.NORMAL, true, [1], ~2) "~0.1E~2" 
        val case_NORMAL_N_2_0 as () = test (R.NORMAL, true, [1, 2], 0) "~0.12" 
        val case_NORMAL_N_2_1 as () = test (R.NORMAL, true, [1, 2], 1) "~0.12E1" 
        val case_NORMAL_N_2_2 as () = test (R.NORMAL, true, [1, 2], 2) "~0.12E2" 
        val case_NORMAL_N_2_3 as () = test (R.NORMAL, true, [1, 2], 3) "~0.12E3" 
        val case_NORMAL_N_2_m1 as () = test (R.NORMAL, true, [1, 2], ~1) "~0.12E~1" 
        val case_NORMAL_N_2_m2 as () = test (R.NORMAL, true, [1, 2], ~2) "~0.12E~2" 
        val case_NORMAL_N_2_m3 as () = test (R.NORMAL, true, [1, 2], ~3) "~0.12E~3" 
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected =
        assertEqualDecOption (SOME (makeDec expected)) (R.fromString arg)
  in

  fun fromString_inf () =
      let
        val case_n_inf as () = test "inf" (R.INF, false, [], 0)
        val case_p_inf as () = test "+inf" (R.INF, false, [], 0)
        val case_m_inf as () = test "-inf" (R.INF, true, [], 0)
        val case_t_inf as () = test "~inf" (R.INF, true, [], 0)
        val case_upper_inf as () = test "INF" (R.INF, false, [], 0)
      in () end

  fun fromString_infinity () =
      let
        val case_n_infinity as () = test "infinity" (R.INF, false, [], 0)
        val case_p_infinity as () = test "+infinity" (R.INF, false, [], 0)
        val case_m_infinity as () = test "-infinity" (R.INF, true, [], 0)
        val case_t_infinity as () = test "~infinity" (R.INF, true, [], 0)
        val case_upper_infinity as () = test "INFINITY" (R.INF, false, [], 0)
      in () end

  fun fromString_nan () =
      let
(*
        val case_n_nan as () = test "nan" (R.NAN, false, [], 0)
        val case_p_nan as () = test "+nan" (R.NAN, false, [], 0)
        val case_m_nan as () = test "-nan" (R.NAN, true, [], 0)
        val case_t_nan as () = test "~nan" (R.NAN, true, [], 0)
        val case_upper_nan as () = test "NAN" (R.NAN, false, [], 0)
*)
      in () end

  (* The fromString must parse the following regular expression.
   * [+~-]?([0-9]+.[0-9]+? | .[0-9]+)(e | E)[+~-]?[0-9]+? 
   *)

  fun fromString_integer () =
      let
        (* test of integer part
         * [+~-]?[0-9]+.(e|E) 
         *)
        val case_n_0e as () = test "0.e" (R.ZERO, false, [], 0)
        val case_n_0E as () = test "0.E" (R.ZERO, false, [], 0)
        val case_01 as () = test "01." (R.NORMAL, false, [1], 1)
        val case_012 as () = test "012." (R.NORMAL, false, [1, 2], 2)
      in () end

  fun fromString_fraction () =
      let
        (* test of fraction part
         * [+~-]?.[0-9]+(e|E)
         *)
        val case_0 as () = test ".0e0" (R.ZERO, false, [], 0)
        val case_1 as () = test ".1e" (R.NORMAL, false, [1], 0)
        val case_0120 as () = test ".0120e" (R.NORMAL, false, [1, 2], ~1)
      in () end

  fun fromString_integer_fraction () =
      let
        (* test of integer+fraction part
         * [+~-]?[0-9]+.[0-9]+(e|E) 
         *)
        val case_0_0 as () = test "0.0e" (R.ZERO, false, [], 0)
        val case_0_1 as () = test "0.1e" (R.NORMAL, false, [1], 0)
        val case_1_0 as () = test "1.0e" (R.NORMAL, false, [1], 1)
        val case_0_0120 as () = test "0.0120e" (R.NORMAL, false, [1, 2], ~1)
        val case_0120_0 as () = test "0120.0e" (R.NORMAL, false, [1, 2], 3)
        val case_0120_0120 as () = test "0120.0120e" (R.NORMAL, false, [1, 2, 0, 0, 1, 2], 3)
      in () end

  fun fromString_exp () =
      let
        (* test of exp part
         * [+~-]?[0-9]+.[0-9]+(e|E)[+~-]?[0-9]+ 
         *)
        val case_0_0_0 as () = test "0.0e0" (R.ZERO, false, [], 0)
        val case_0120_0120_1 as () = test "0120.0120e1" (R.NORMAL, false, [1, 2, 0, 0, 1, 2], 4)
        val case_0120_0120_p1 as () = test "0120.0120e+1" (R.NORMAL, false, [1, 2, 0, 0, 1, 2], 4)
        val case_0120_0120_m1 as () = test "0120.0120e-1" (R.NORMAL, false, [1, 2, 0, 0, 1, 2], 2)
        val case_0120_0120_t1 as () = test "0120.0120e~1" (R.NORMAL, false, [1, 2, 0, 0, 1, 2], 2)
      in () end

  fun fromString_sign () =
      let
        (* test of sign part
         *)
        val case_p_0 as () = test "+0.E" (R.ZERO, false, [], 0)
        val case_m_0 as () = test "-0.E" (R.ZERO, true, [], 0)
        val case_t_0 as () = test "~0.E" (R.ZERO, true, [], 0)
        val case_p_0120_0120_t1 as () = test "+0120.0120e~1" (R.NORMAL, false, [1, 2, 0, 0, 1, 2], 2)
        val case_m_0120_0120_t1 as () = test "-0120.0120e~1" (R.NORMAL, true, [1, 2, 0, 0, 1, 2], 2)
        val case_t_0120_0120_t1 as () = test "~0120.0120e~1" (R.NORMAL, true, [1, 2, 0, 0, 1, 2], 2)
      in () end

  fun fromString_header_trailer () =
      let
        (* test of leading white spaces and trailers
         *)
        val case_ws_p_0120_0120_t1 as () = test "  +0120.0120e~1abc" (R.NORMAL, false, [1, 2, 0, 0, 1, 2], 2)
      in () end

  fun fromString_invalid1 () =
      let
        val fromString_alpha = R.fromString "A"
        val () = assertNone fromString_alpha

        val fromString_onlyE = R.fromString "E"
        val () = assertNone fromString_onlyE

(*
        val fromString_nodot = R.fromString "123"
        val () = assertNone fromString_nodot
*)
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
