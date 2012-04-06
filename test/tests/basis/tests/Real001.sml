val abs_0 = Real.abs 0.0;
val abs_p = Real.abs 1.23;
val abs_m = Real.abs ~1.23;

val min_0_0 = Real.min (0.0, 0.0);
val min_p_p_l = Real.min (1.23, 2.34);
val min_p_p_g = Real.min (2.34, 1.23);
val min_m_m_l = Real.min (~2.34, ~1.23);
val min_m_m_g = Real.min (~1.23, ~2.34);
val min_m_p = Real.min (~2.34, 1.23);
val min_p_m = Real.min (1.23, ~2.34);

val max_0_0 = Real.max (0.0, 0.0);
val max_p_p_l = Real.max (1.23, 2.34);
val max_p_p_g = Real.max (2.34, 1.23);
val max_m_m_l = Real.max (~2.34, ~1.23);
val max_m_m_g = Real.max (~1.23, ~2.34);
val max_m_p = Real.max (~2.34, 1.23);
val max_p_m = Real.max (1.23, ~2.34);

val sign_0 = Real.sign 0.0;
val sign_p = Real.sign 1.23;
val sign_m = Real.sign ~1.23;

val signBit_0 = Real.signBit 0.0;
val signBit_p = Real.signBit 1.23;
val signBit_m = Real.signBit ~1.23;

val sameSign_0_0 = Real.sameSign (0.0, 0.0);
val sameSign_p_p = Real.sameSign (1.23, 2.34);
val sameSign_m_m = Real.sameSign (~2.34, ~1.23);
val sameSign_m_p = Real.sameSign (~2.34, 1.23);
val sameSign_p_m = Real.sameSign (1.23, ~2.34);

val copySign_0_0 = Real.copySign (0.0, 0.0);
val copySign_p_p = Real.copySign (1.23, 2.34);
val copySign_m_m = Real.copySign (~2.34, ~1.23);
val copySign_m_p = Real.copySign (~2.34, 1.23);
val copySign_p_m = Real.copySign (1.23, ~2.34);

val compare_0_0 = Real.compare (0.0, 0.0);
val compare_p_p_l = Real.compare (1.23, 2.34);
val compare_p_p_g = Real.compare (2.34, 1.23);
val compare_p_p_e = Real.compare (1.23, 1.23);
val compare_m_m_l = Real.compare (~2.34, ~1.23);
val compare_m_m_g = Real.compare (~1.23, ~2.34);
val compare_m_m_e = Real.compare (~2.34, ~2.34);
val compare_m_p = Real.compare (~2.34, 1.23);
val compare_p_m = Real.compare (1.23, ~2.34);

val compareReal_0_0 = Real.compareReal (0.0, 0.0);
val compareReal_p_p_l = Real.compareReal (1.23, 2.34);
val compareReal_p_p_g = Real.compareReal (2.34, 1.23);
val compareReal_p_p_e = Real.compareReal (1.23, 1.23);
val compareReal_m_m_l = Real.compareReal (~2.34, ~1.23);
val compareReal_m_m_g = Real.compareReal (~1.23, ~2.34);
val compareReal_m_m_e = Real.compareReal (~2.34, ~2.34);
val compareReal_m_p = Real.compareReal (~2.34, 1.23);
val compareReal_p_m = Real.compareReal (1.23, ~2.34);

fun testBinComp args =
    (Real.< args, Real.<= args, Real.> args, Real.>= args);
val binComp_0_0 = testBinComp (0.0, 0.0);
val binComp_p_p_l = testBinComp (1.23, 2.34);
val binComp_p_p_g = testBinComp (2.34, 1.23);
val binComp_p_p_e = testBinComp (1.23, 1.23);
val binComp_m_m_l = testBinComp (~2.34, ~1.23);
val binComp_m_m_g = testBinComp (~1.23, ~2.34);
val binComp_m_m_e = testBinComp (~2.34, ~2.34);
val binComp_m_p = testBinComp (~2.34, 1.23);
val binComp_p_m = testBinComp (1.23, ~2.34);

fun testIEEEEq args =
    (Real.== args, Real.!= args, Real.?= args, Real.unordered args);
val IEEEEqOp_0_0 = testIEEEEq (0.0, 0.0);
val IEEEEqOp_p_p_l = testIEEEEq (1.23, 2.34);
val IEEEEqOp_p_p_g = testIEEEEq (2.34, 1.23);
val IEEEEqOp_p_p_e = testIEEEEq (1.23, 1.23);
val IEEEEqOp_m_m_l = testIEEEEq (~2.34, ~1.23);
val IEEEEqOp_m_m_g = testIEEEEq (~1.23, ~2.34);
val IEEEEqOp_m_m_e = testIEEEEq (~2.34, ~2.34);
val IEEEEqOp_m_p = testIEEEEq (~2.34, 1.23);
val IEEEEqOp_p_m = testIEEEEq (1.23, ~2.34);

val isFinite_0 = Real.isFinite 0.0;
val isFinite_n = Real.isFinite 1.23;

val isNan_0 = Real.isNan 0.0;
val isNan_n = Real.isNan 1.23;

val isNormal_0 = Real.isNormal 0.0;
val isNormal_n = Real.isNormal 1.23;

val toManExp_0 = Real.toManExp 0.0;
val toManExp_p = Real.toManExp 123.456;
val toManExp_m = Real.toManExp ~123.456;

(*
val fromManExp_0_0 = Real.fromManExp {man = 0.0, exp = 0};
*)
val fromManExp_p_p = Real.fromManExp {man = 12.3, exp = 4};
val fromManExp_p_m = Real.fromManExp {man = 12.3, exp = ~4};
val fromManExp_m_p = Real.fromManExp {man = ~12.3, exp = 4};
val fromManExp_m_m = Real.fromManExp {man = ~12.3, exp = ~4};

val split_0 = Real.split 0.0;
val split_p = Real.split 123.456;
val split_m = Real.split ~123.456;

val realMod_0 = Real.realMod 0.0;
val realMod_p = Real.realMod 123.456;
val realMod_m = Real.realMod ~123.456;

val floor_0 = Real.floor 0.0;
val floor_1_4 = Real.floor 1.4;
val floor_1_5 = Real.floor 1.5;
val floor_m1_4 = Real.floor ~1.4;
val floor_m1_5 = Real.floor ~1.5;

val ceil_0 = Real.ceil 0.0;
val ceil_1_4 = Real.ceil 1.4;
val ceil_1_5 = Real.ceil 1.5;
val ceil_m1_4 = Real.ceil ~1.4;
val ceil_m1_5 = Real.ceil ~1.5;

val trunc_0 = Real.trunc 0.0;
val trunc_1_4 = Real.trunc 1.4;
val trunc_1_5 = Real.trunc 1.5;
val trunc_m1_4 = Real.trunc ~1.4;
val trunc_m1_5 = Real.trunc ~1.5;

val round_0 = Real.round 0.0;
val round_1_4 = Real.round 1.4;
val round_1_5 = Real.round 1.5;
val round_m1_4 = Real.round ~1.4;
val round_m1_5 = Real.round ~1.5;

val realFloor_0 = Real.realFloor 0.0;
val realFloor_1_4 = Real.realFloor 1.4;
val realFloor_1_5 = Real.realFloor 1.5;
val realFloor_m1_4 = Real.realFloor ~1.4;
val realFloor_m1_5 = Real.realFloor ~1.5;

val realCeil_0 = Real.realCeil 0.0;
val realCeil_1_4 = Real.realCeil 1.4;
val realCeil_1_5 = Real.realCeil 1.5;
val realCeil_m1_4 = Real.realCeil ~1.4;
val realCeil_m1_5 = Real.realCeil ~1.5;

val realTrunc_0 = Real.realTrunc 0.0;
val realTrunc_1_4 = Real.realTrunc 1.4;
val realTrunc_1_5 = Real.realTrunc 1.5;
val realTrunc_m1_4 = Real.realTrunc ~1.4;
val realTrunc_m1_5 = Real.realTrunc ~1.5;

val realRound_0 = Real.realRound 0.0;
val realRound_1_4 = Real.realRound 1.4;
val realRound_1_5 = Real.realRound 1.5;
val realRound_m1_4 = Real.realRound ~1.4;
val realRound_m1_5 = Real.realRound ~1.5;

val toString_m11 = Real.toString 0.00123456789;
val toString_m12 = Real.toString 0.000123456789;
val toString_m13 = Real.toString 0.0000123456789;
val toString_11 = Real.toString 12345678900.0;
val toString_12 = Real.toString 123456789000.0;
val toString_13 = Real.toString 1234567890000.0;

val fmt_FIX_1239_2 = Real.fmt (StringCvt.FIX (SOME 2)) 1.239;
val fmt_FIX_1239_3 = Real.fmt (StringCvt.FIX (SOME 3)) 1.239;
val fmt_FIX_1239_4 = Real.fmt (StringCvt.FIX (SOME 4)) 1.239;

val fmt_FIX_1299_1 = Real.fmt (StringCvt.FIX (SOME 1)) 1.299;
val fmt_FIX_1299_2 = Real.fmt (StringCvt.FIX (SOME 2)) 1.299;
val fmt_FIX_1299_3 = Real.fmt (StringCvt.FIX (SOME 3)) 1.299;

val fmt_FIX_19_0 = Real.fmt (StringCvt.FIX (SOME 0)) 1.9;
val fmt_FIX_19_1 = Real.fmt (StringCvt.FIX (SOME 1)) 1.9;

