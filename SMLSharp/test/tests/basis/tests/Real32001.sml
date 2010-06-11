val abs_0 = Real32.abs 0.0;
val abs_p = Real32.abs 1.23;
val abs_m = Real32.abs ~1.23;

val min_0_0 = Real32.min (0.0, 0.0);
val min_p_p_l = Real32.min (1.23, 2.34);
val min_p_p_g = Real32.min (2.34, 1.23);
val min_m_m_l = Real32.min (~2.34, ~1.23);
val min_m_m_g = Real32.min (~1.23, ~2.34);
val min_m_p = Real32.min (~2.34, 1.23);
val min_p_m = Real32.min (1.23, ~2.34);

val max_0_0 = Real32.max (0.0, 0.0);
val max_p_p_l = Real32.max (1.23, 2.34);
val max_p_p_g = Real32.max (2.34, 1.23);
val max_m_m_l = Real32.max (~2.34, ~1.23);
val max_m_m_g = Real32.max (~1.23, ~2.34);
val max_m_p = Real32.max (~2.34, 1.23);
val max_p_m = Real32.max (1.23, ~2.34);

val sign_0 = Real32.sign 0.0;
val sign_p = Real32.sign 1.23;
val sign_m = Real32.sign ~1.23;

val signBit_0 = Real32.signBit 0.0;
val signBit_p = Real32.signBit 1.23;
val signBit_m = Real32.signBit ~1.23;

val sameSign_0_0 = Real32.sameSign (0.0, 0.0);
val sameSign_p_p = Real32.sameSign (1.23, 2.34);
val sameSign_m_m = Real32.sameSign (~2.34, ~1.23);
val sameSign_m_p = Real32.sameSign (~2.34, 1.23);
val sameSign_p_m = Real32.sameSign (1.23, ~2.34);

val copySign_0_0 = Real32.copySign (0.0, 0.0);
val copySign_p_p = Real32.copySign (1.23, 2.34);
val copySign_m_m = Real32.copySign (~2.34, ~1.23);
val copySign_m_p = Real32.copySign (~2.34, 1.23);
val copySign_p_m = Real32.copySign (1.23, ~2.34);

val compare_0_0 = Real32.compare (0.0, 0.0);
val compare_p_p_l = Real32.compare (1.23, 2.34);
val compare_p_p_g = Real32.compare (2.34, 1.23);
val compare_p_p_e = Real32.compare (1.23, 1.23);
val compare_m_m_l = Real32.compare (~2.34, ~1.23);
val compare_m_m_g = Real32.compare (~1.23, ~2.34);
val compare_m_m_e = Real32.compare (~2.34, ~2.34);
val compare_m_p = Real32.compare (~2.34, 1.23);
val compare_p_m = Real32.compare (1.23, ~2.34);

val compareReal_0_0 = Real32.compareReal (0.0, 0.0);
val compareReal_p_p_l = Real32.compareReal (1.23, 2.34);
val compareReal_p_p_g = Real32.compareReal (2.34, 1.23);
val compareReal_p_p_e = Real32.compareReal (1.23, 1.23);
val compareReal_m_m_l = Real32.compareReal (~2.34, ~1.23);
val compareReal_m_m_g = Real32.compareReal (~1.23, ~2.34);
val compareReal_m_m_e = Real32.compareReal (~2.34, ~2.34);
val compareReal_m_p = Real32.compareReal (~2.34, 1.23);
val compareReal_p_m = Real32.compareReal (1.23, ~2.34);

fun testBinComp args =
    (Real32.< args, Real32.<= args, Real32.> args, Real32.>= args);
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
    (Real32.== args, Real32.!= args, Real32.?= args, Real32.unordered args);
val IEEEEqOp_0_0 = testIEEEEq (0.0, 0.0);
val IEEEEqOp_p_p_l = testIEEEEq (1.23, 2.34);
val IEEEEqOp_p_p_g = testIEEEEq (2.34, 1.23);
val IEEEEqOp_p_p_e = testIEEEEq (1.23, 1.23);
val IEEEEqOp_m_m_l = testIEEEEq (~2.34, ~1.23);
val IEEEEqOp_m_m_g = testIEEEEq (~1.23, ~2.34);
val IEEEEqOp_m_m_e = testIEEEEq (~2.34, ~2.34);
val IEEEEqOp_m_p = testIEEEEq (~2.34, 1.23);
val IEEEEqOp_p_m = testIEEEEq (1.23, ~2.34);

val isFinite_0 = Real32.isFinite 0.0;
val isFinite_n = Real32.isFinite 1.23;

val isNan_0 = Real32.isNan 0.0;
val isNan_n = Real32.isNan 1.23;

val isNormal_0 = Real32.isNormal 0.0;
val isNormal_n = Real32.isNormal 1.23;

val toManExp_0 = Real32.toManExp 0.0;
val toManExp_p = Real32.toManExp 123.456;
val toManExp_m = Real32.toManExp ~123.456;

(*
val fromManExp_0_0 = Real32.fromManExp {man = 0.0, exp = 0};
*)
val fromManExp_p_p = Real32.fromManExp {man = 12.3, exp = 4};
val fromManExp_p_m = Real32.fromManExp {man = 12.3, exp = ~4};
val fromManExp_m_p = Real32.fromManExp {man = ~12.3, exp = 4};
val fromManExp_m_m = Real32.fromManExp {man = ~12.3, exp = ~4};

val split_0 = Real32.split 0.0;
val split_p = Real32.split 123.456;
val split_m = Real32.split ~123.456;

val realMod_0 = Real32.realMod 0.0;
val realMod_p = Real32.realMod 123.456;
val realMod_m = Real32.realMod ~123.456;

val floor_0 = Real32.floor 0.0;
val floor_1_4 = Real32.floor 1.4;
val floor_1_5 = Real32.floor 1.5;
val floor_m1_4 = Real32.floor ~1.4;
val floor_m1_5 = Real32.floor ~1.5;

val ceil_0 = Real32.ceil 0.0;
val ceil_1_4 = Real32.ceil 1.4;
val ceil_1_5 = Real32.ceil 1.5;
val ceil_m1_4 = Real32.ceil ~1.4;
val ceil_m1_5 = Real32.ceil ~1.5;

val trunc_0 = Real32.trunc 0.0;
val trunc_1_4 = Real32.trunc 1.4;
val trunc_1_5 = Real32.trunc 1.5;
val trunc_m1_4 = Real32.trunc ~1.4;
val trunc_m1_5 = Real32.trunc ~1.5;

val round_0 = Real32.round 0.0;
val round_1_4 = Real32.round 1.4;
val round_1_5 = Real32.round 1.5;
val round_m1_4 = Real32.round ~1.4;
val round_m1_5 = Real32.round ~1.5;

val realFloor_0 = Real32.realFloor 0.0;
val realFloor_1_4 = Real32.realFloor 1.4;
val realFloor_1_5 = Real32.realFloor 1.5;
val realFloor_m1_4 = Real32.realFloor ~1.4;
val realFloor_m1_5 = Real32.realFloor ~1.5;

val realCeil_0 = Real32.realCeil 0.0;
val realCeil_1_4 = Real32.realCeil 1.4;
val realCeil_1_5 = Real32.realCeil 1.5;
val realCeil_m1_4 = Real32.realCeil ~1.4;
val realCeil_m1_5 = Real32.realCeil ~1.5;

val realTrunc_0 = Real32.realTrunc 0.0;
val realTrunc_1_4 = Real32.realTrunc 1.4;
val realTrunc_1_5 = Real32.realTrunc 1.5;
val realTrunc_m1_4 = Real32.realTrunc ~1.4;
val realTrunc_m1_5 = Real32.realTrunc ~1.5;

val realRound_0 = Real32.realRound 0.0;
val realRound_1_4 = Real32.realRound 1.4;
val realRound_1_5 = Real32.realRound 1.5;
val realRound_m1_4 = Real32.realRound ~1.4;
val realRound_m1_5 = Real32.realRound ~1.5;

val toString_m11 = Real32.toString 0.00123456789;
val toString_m12 = Real32.toString 0.000123456789;
val toString_m13 = Real32.toString 0.0000123456789;
val toString_11 = Real32.toString 12345678900.0;
val toString_12 = Real32.toString 123456789000.0;
val toString_13 = Real32.toString 1234567890000.0;

val fmt_FIX_1239_2 = Real32.fmt (StringCvt.FIX (SOME 2)) 1.239;
val fmt_FIX_1239_3 = Real32.fmt (StringCvt.FIX (SOME 3)) 1.239;
val fmt_FIX_1239_4 = Real32.fmt (StringCvt.FIX (SOME 4)) 1.239;

val fmt_FIX_1299_1 = Real32.fmt (StringCvt.FIX (SOME 1)) 1.299;
val fmt_FIX_1299_2 = Real32.fmt (StringCvt.FIX (SOME 2)) 1.299;
val fmt_FIX_1299_3 = Real32.fmt (StringCvt.FIX (SOME 3)) 1.299;

val fmt_FIX_19_0 = Real32.fmt (StringCvt.FIX (SOME 0)) 1.9;
val fmt_FIX_19_1 = Real32.fmt (StringCvt.FIX (SOME 1)) 1.9;

