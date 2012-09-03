(*
test cases for IEEEReal structure.
*)
fun makeDec (kind, sign, digits, exp) =
    {kind = kind, sign = sign, digits = digits, exp = exp}
    : IEEEReal.decimal_approx;

(********************)
val roundingMode_TO_NEAREST =
    (IEEEReal.setRoundingMode IEEEReal.TO_NEAREST; IEEEReal.getRoundingMode());
val roundingMode_TO_NEGINF =
    (IEEEReal.setRoundingMode IEEEReal.TO_NEGINF; IEEEReal.getRoundingMode ());
val roundingMode_TO_POSINF =
    (IEEEReal.setRoundingMode IEEEReal.TO_POSINF; IEEEReal.getRoundingMode ());
val roundingMode_TO_ZERO =
    (IEEEReal.setRoundingMode IEEEReal.TO_ZERO; IEEEReal.getRoundingMode ());

(********************)
val toString_NAN_QUIET =
    IEEEReal.toString(makeDec (IEEEReal.NAN(IEEEReal.QUIET), false, [], 0));
val toString_NAN_SIGNALLING =
    IEEEReal.toString
        (makeDec (IEEEReal.NAN(IEEEReal.SIGNALLING), false, [], 0));
val toString_POS_INF = IEEEReal.toString(makeDec (IEEEReal.INF, false, [], 0));
val toString_NEG_INF = IEEEReal.toString(makeDec (IEEEReal.INF, true, [], 0));
val toString_POS_ZERO =
    IEEEReal.toString(makeDec (IEEEReal.ZERO, false, [], 0));
val toString_NEG_ZERO =
    IEEEReal.toString(makeDec (IEEEReal.ZERO, true, [], 0));
val toString_NORMAL_P_0_0 =
    IEEEReal.toString(makeDec (IEEEReal.NORMAL, false, [0], 0));
val toString_NORMAL_P_1_0 =
    IEEEReal.toString(makeDec (IEEEReal.NORMAL, false, [1], 0));
val toString_NORMAL_P_1_1 =
    IEEEReal.toString(makeDec (IEEEReal.NORMAL, false, [1], 1));
val toString_NORMAL_P_1_2 =
    IEEEReal.toString(makeDec (IEEEReal.NORMAL, false, [1], 2));
val toString_NORMAL_P_1_m1 =
    IEEEReal.toString(makeDec (IEEEReal.NORMAL, false, [1], ~1));
val toString_NORMAL_P_1_m2 =
    IEEEReal.toString(makeDec (IEEEReal.NORMAL, false, [1], ~2));
val toString_NORMAL_P_2_0 =
    IEEEReal.toString(makeDec (IEEEReal.NORMAL, false, [1, 2], 0));
val toString_NORMAL_P_2_1 =
    IEEEReal.toString(makeDec (IEEEReal.NORMAL, false, [1, 2], 1));
val toString_NORMAL_P_2_2 =
    IEEEReal.toString(makeDec (IEEEReal.NORMAL, false, [1, 2], 2));
val toString_NORMAL_P_2_3 =
    IEEEReal.toString(makeDec (IEEEReal.NORMAL, false, [1, 2], 3));
val toString_NORMAL_P_n_m1 =
    IEEEReal.toString(makeDec (IEEEReal.NORMAL, false, [1, 2], ~1));
val toString_NORMAL_P_n_m2 =
    IEEEReal.toString(makeDec (IEEEReal.NORMAL, false, [1, 2], ~2));
val toString_NORMAL_P_n_m3 =
    IEEEReal.toString(makeDec (IEEEReal.NORMAL, false, [1, 2], ~3));
(**********)
val toString_NORMAL_N_0_0 =
    IEEEReal.toString(makeDec (IEEEReal.NORMAL, true, [0], 0));
val toString_NORMAL_N_1_0 =
    IEEEReal.toString(makeDec (IEEEReal.NORMAL, true, [1], 0));
val toString_NORMAL_N_1_1 =
    IEEEReal.toString(makeDec (IEEEReal.NORMAL, true, [1], 1));
val toString_NORMAL_N_1_2 =
    IEEEReal.toString(makeDec (IEEEReal.NORMAL, true, [1], 2));
val toString_NORMAL_N_1_m1 =
    IEEEReal.toString(makeDec (IEEEReal.NORMAL, true, [1], ~1));
val toString_NORMAL_N_1_m2 =
    IEEEReal.toString(makeDec (IEEEReal.NORMAL, true, [1], ~2));
val toString_NORMAL_N_2_0 =
    IEEEReal.toString(makeDec (IEEEReal.NORMAL, true, [1, 2], 0));
val toString_NORMAL_N_2_1 =
    IEEEReal.toString(makeDec (IEEEReal.NORMAL, true, [1, 2], 1));
val toString_NORMAL_N_2_2 =
    IEEEReal.toString(makeDec (IEEEReal.NORMAL, true, [1, 2], 2));
val toString_NORMAL_N_2_3 =
    IEEEReal.toString(makeDec (IEEEReal.NORMAL, true, [1, 2], 3));
val toString_NORMAL_N_n_m1 =
    IEEEReal.toString(makeDec (IEEEReal.NORMAL, true, [1, 2], ~1));
val toString_NORMAL_N_n_m2 =
    IEEEReal.toString(makeDec (IEEEReal.NORMAL, true, [1, 2], ~2));
val toString_NORMAL_N_n_m3 =
    IEEEReal.toString(makeDec (IEEEReal.NORMAL, true, [1, 2], ~3));
(********************)

val fromString_n_inf = IEEEReal.fromString "inf";
val fromString_p_inf = IEEEReal.fromString "+inf";
val fromString_m_inf = IEEEReal.fromString "-inf";
val fromString_t_inf = IEEEReal.fromString "~inf";

val fromString_n_infinity = IEEEReal.fromString "infinity";
val fromString_p_infinity = IEEEReal.fromString "+infinity";
val fromString_m_infinity = IEEEReal.fromString "-infinity";
val fromString_t_infinity = IEEEReal.fromString "~infinity";

val fromString_n_nan = IEEEReal.fromString "nan";
val fromString_p_nan = IEEEReal.fromString "+nan";
val fromString_m_nan = IEEEReal.fromString "-nan";
val fromString_t_nan = IEEEReal.fromString "~nan";

(* The fromString must parse the following regular expression.
   [+~-]?([0-9]+.[0-9]+? | .[0-9]+)(e | E)[+~-]?[0-9]+? 
*)
(* test of integer part
           [+~-]?[0-9]+.(e|E) 
*)
val fromString_n_0e = IEEEReal.fromString "0.e";
val fromString_n_0E = IEEEReal.fromString "0.E";
val fromString_01 = IEEEReal.fromString "01.";
val fromString_012 = IEEEReal.fromString "012.";
(* test of fraction part
    [+~-]?.[0-9]+(e|E)
*)
val fromString_0 = IEEEReal.fromString ".0e0";
val fromString_1 = IEEEReal.fromString ".1e";
val fromString_0120 = IEEEReal.fromString ".0120e";
(* test of integer+fraction part
    [+~-]?[0-9]+.[0-9]+(e|E) 
*)
val fromString_0_0 = IEEEReal.fromString "0.0e";
val fromString_0_1 = IEEEReal.fromString "0.1e";
val fromString_1_0 = IEEEReal.fromString "1.0e";
val fromString_0_0120 = IEEEReal.fromString "0.0120e";
val fromString_0120_0 = IEEEReal.fromString "0120.0e";
val fromString_0120_0120 = IEEEReal.fromString "0120.0120e";
(* test of exp part
    [+~-]?[0-9]+.[0-9]+(e|E)[+~-]?[0-9]+ 
*)
val fromString_0_0_0 = IEEEReal.fromString "0.0e0";
val fromString_0120_0120_1 = IEEEReal.fromString "0120.0120e1";
val fromString_0120_0120_p1 = IEEEReal.fromString "0120.0120e+1";
val fromString_0120_0120_m1 = IEEEReal.fromString "0120.0120e-1";
val fromString_0120_0120_t1 = IEEEReal.fromString "0120.0120e~1";
(* test of sign part
*)
val fromString_p_0 = IEEEReal.fromString "+0.E";
val fromString_m_0 = IEEEReal.fromString "-0.E";
val fromString_t_0 = IEEEReal.fromString "~0.E";
val fromString_p_0120_0120_t1 = IEEEReal.fromString "+0120.0120e~1";
val fromString_m_0120_0120_t1 = IEEEReal.fromString "-0120.0120e~1";
val fromString_t_0120_0120_t1 = IEEEReal.fromString "~0120.0120e~1";
(* test of leading white spaces and trailers
*)
val fromString_ws_p_0120_0120_t1 = IEEEReal.fromString "  +0120.0120e~1abc";
