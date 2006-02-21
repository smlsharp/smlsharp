fun toInt time = Time.toMicroseconds time handle Overflow => 999;

val fromReal_0 = toInt(Time.fromReal 0.0);
val fromReal_p = toInt(Time.fromReal 12.34);
val fromReal_m = toInt(Time.fromReal ~12.34) handle Time.Time => 999;

val toReal_0 = Time.toReal (Time.fromReal 0.0);
val toReal_p = Time.toReal (Time.fromReal 12.34);
val toReal_m = Time.toReal (Time.fromReal ~12.34) handle Time.Time => 9.99;

val fromSeconds_0 = toInt(Time.fromSeconds 0);
val fromSeconds_p = toInt(Time.fromSeconds 123);
val fromSeconds_m = toInt(Time.fromSeconds ~123) handle Time.Time => 999;

val toSeconds_0 = Time.toSeconds(Time.fromSeconds 0);
val toSeconds_p = Time.toSeconds(Time.fromSeconds 123);
val toSeconds_m =
    Time.toSeconds(Time.fromSeconds ~123) handle Time.Time => 999;

val fromMilliseconds_0 = toInt(Time.fromMilliseconds 0);
val fromMilliseconds_p1 = toInt(Time.fromMilliseconds 123);
val fromMilliseconds_p2 = toInt(Time.fromMilliseconds 123456);
val fromMilliseconds_p3 = toInt(Time.fromMilliseconds 123456789);
(*
val fromMilliseconds_m1 =
    toInt(Time.fromMilliseconds ~123) handle Time.Time => 999;
val fromMilliseconds_m2 =
    toInt(Time.fromMilliseconds ~123456) handle Time.Time => 999;
val fromMilliseconds_m3 =
    toInt(Time.fromMilliseconds ~123456789) handle Time.Time => 999;
*)

val toMicroseconds_0 = Time.toMicroseconds(Time.fromMicroseconds 0);
val toMicroseconds_p1 = Time.toMicroseconds(Time.fromMicroseconds 123);
val toMicroseconds_p2 = Time.toMicroseconds(Time.fromMicroseconds 123456);
val toMicroseconds_p3 = Time.toMicroseconds(Time.fromMicroseconds 123456789);
(*
val toMicroseconds_m1 =
    Time.toMicroseconds(Time.fromMicroseconds ~123) handle Time.Time => 999;
val toMicroseconds_m2 =
    Time.toMicroseconds(Time.fromMicroseconds ~123456) handle Time.Time => 999;
val toMicroseconds_m3 =
    Time.toMicroseconds(Time.fromMicroseconds ~123456789)
    handle Time.Time => 999;
*)

val fromMicroseconds_0 = toInt(Time.fromMicroseconds 0);
val fromMicroseconds_p1 = toInt(Time.fromMicroseconds 123);
val fromMicroseconds_p2 = toInt(Time.fromMicroseconds 123456);
val fromMicroseconds_p3 = toInt(Time.fromMicroseconds 123456789);
(*
val fromMicroseconds_m1 =
    toInt(Time.fromMicroseconds ~123) handle Time.Time => 999;
val fromMicroseconds_m2 =
    toInt(Time.fromMicroseconds ~123456) handle Time.Time => 999;
val fromMicroseconds_m3 =
    toInt(Time.fromMicroseconds ~123456789) handle Time.Time => 999;
*)

val toMicroseconds_0 = Time.toMicroseconds(Time.fromMicroseconds 0);
val toMicroseconds_p1 = Time.toMicroseconds(Time.fromMicroseconds 123);
val toMicroseconds_p2 = Time.toMicroseconds(Time.fromMicroseconds 123456);
val toMicroseconds_p3 = Time.toMicroseconds(Time.fromMicroseconds 123456789);
(*
val toMicroseconds_m1 =
    Time.toMicroseconds(Time.fromMicroseconds ~123) handle Time.Time => 999;
val toMicroseconds_m2 =
    Time.toMicroseconds(Time.fromMicroseconds ~123456) handle Time.Time => 999;
val toMicroseconds_m3 =
    Time.toMicroseconds(Time.fromMicroseconds ~123456789)
    handle Time.Time => 999;
*)

(*
val fromNanoseconds_0 = toInt(Time.fromNanoseconds 0);
val fromNanoseconds_p1 = toInt(Time.fromNanoseconds 123);
val fromNanoseconds_p2 = toInt(Time.fromNanoseconds 123456);
val fromNanoseconds_p3 = toInt(Time.fromNanoseconds 123456789);
val fromNanoseconds_m1 =
    toInt(Time.fromNanoseconds ~123) handle Time.Time => 999;
val fromNanoseconds_m2 =
    toInt(Time.fromNanoseconds ~123456) handle Time.Time => 999;
val fromNanoseconds_m3 =
    toInt(Time.fromNanoseconds ~123456789) handle Time.Time => 999;

val toNanoseconds_0 = Time.toNanoseconds(Time.fromNanoseconds 0);
val toNanoseconds_p1 = Time.toNanoseconds(Time.fromNanoseconds 123);
val toNanoseconds_p2 = Time.toNanoseconds(Time.fromNanoseconds 123456);
val toNanoseconds_p3 = Time.toNanoseconds(Time.fromNanoseconds 123456789);
val toNanoseconds_m1 =
    Time.toNanoseconds(Time.fromNanoseconds ~123) handle Time.Time => 999;
val toNanoseconds_m2 =
    Time.toNanoseconds(Time.fromNanoseconds ~123456) handle Time.Time => 999;
val toNanoseconds_m3 =
    Time.toNanoseconds(Time.fromNanoseconds ~123456789)
    handle Time.Time => 999;
*)

fun testBinArithOp operator (sec1, usec1, sec2, usec2) =
    let
      val t1 = Time.fromMicroseconds (sec1 * 1000000 + usec1)
      val t2 = Time.fromMicroseconds (sec2 * 1000000 + usec2)
      val t = operator (t1, t2)
    in
      Time.toMicroseconds t
    end
      handle Time.Time => 999;
val testAdd = testBinArithOp Time.+;
val add_00_00 = testAdd(0, 0, 0, 0);
val add_11_22 = testAdd(1, 1, 2, 2);
val add_NroundUp = testAdd(1, 500000, 2, 499999); (* no round up *)
val add_roundUp = testAdd(1, 500000, 2, 500000); (* round up *)

val testSub = testBinArithOp Time.-;
val sub_00_00 = testSub(0, 0, 0, 0);
val sub_11_22 = testSub(2, 2, 1, 1);
val sub_NroundDown = testSub(2, 500000, 1, 499999); (* no round down *)
val sub_NroundDown = testSub(2, 500000, 1, 500000); (* no round down *)
val sub_roundDown = testSub(2, 499999, 1, 500000); (* round down *)

fun testBinCompare comparator (sec1, usec1, sec2, usec2) =
    let
      val t1 = Time.fromMicroseconds (sec1 * 1000000 + usec1)
      val t2 = Time.fromMicroseconds (sec2 * 1000000 + usec2)
    in
      SOME(comparator (t1, t2))
    end
      handle Time.Time => NONE;
val testCompare = testBinCompare Time.compare;
val compare_E_0 = testCompare (0, 0, 0, 0);
val compare_E_p = testCompare (1, 123, 1, 123);
val compare_L_0 = testCompare (0, 0, 1, 0);
val compare_L_1 = testCompare (1, 0, 1, 1);
val compare_G_0 = testCompare (1, 0, 0, 0);
val compare_G_1 = testCompare (1, 1, 1, 0);

val testLess = testBinCompare Time.<;
val less_0 = testLess (0, 0, 0, 0);
val less_t1 = testLess (0, 0, 1, 0);
val less_t2 = testLess (0, 0, 0, 1);
val less_t3 = testLess (0, 2, 1, 0);
val less_f1 = testLess (1, 0, 0, 0);
val less_f2 = testLess (1, 0, 0, 2);
val less_f3 = testLess (1, 2, 1, 2);

val testLessEq = testBinCompare Time.<=;
val lessEq_0 = testLessEq (0, 0, 0, 0);
val lessEq_t1 = testLessEq (0, 0, 1, 0);
val lessEq_t2 = testLessEq (0, 0, 0, 1);
val lessEq_t3 = testLessEq (0, 2, 1, 0);
val lessEq_t4 = testLessEq (1, 2, 1, 2);
val lessEq_f1 = testLessEq (1, 0, 0, 0);
val lessEq_f2 = testLessEq (1, 0, 0, 2);

val testGreater = testBinCompare Time.>;
val greater_0 = testGreater (0, 0, 0, 0);
val greater_t1 = testGreater (1, 0, 0, 0);
val greater_t2 = testGreater (1, 0, 0, 2);
val greater_f1 = testGreater (0, 0, 1, 0);
val greater_f2 = testGreater (0, 0, 0, 1);
val greater_f3 = testGreater (0, 2, 1, 0);
val greater_f4 = testGreater (1, 2, 1, 2);

val testGreaterEq = testBinCompare Time.>=;
val greaterEq_0 = testGreaterEq (0, 0, 0, 0);
val greaterEq_t1 = testGreaterEq (1, 0, 0, 0);
val greaterEq_t2 = testGreaterEq (1, 0, 0, 2);
val greaterEq_t3 = testGreaterEq (1, 2, 1, 2);
val greaterEq_f1 = testGreaterEq (0, 0, 1, 0);
val greaterEq_f2 = testGreaterEq (0, 0, 0, 1);
val greaterEq_f3 = testGreaterEq (0, 2, 1, 0);

val toString_0 = Time.toString Time.zeroTime;
val toString_1 = Time.toString (Time.fromSeconds 123456789);

fun testFromString arg = Option.map Time.toMicroseconds (Time.fromString arg);
val fromString_0 = testFromString "0";
val fromString_n_1_0 = testFromString "1";(* no sign, 1 number, no fraction *)
val fromString_n_1_1 = testFromString "1.2";
val fromString_n_3_3 = testFromString "123.321";
val fromString_n_0_1 = testFromString ".1";
val fromString_n_0_3 = testFromString ".321";
val fromString_p_3_3 = testFromString "+123.321";
val fromString_t_3_3 = testFromString "~123.321";
val fromString_m_3_3 = testFromString "-123.321";

val fmt_0_n = Time.fmt 0 (Time.fromMicroseconds 123456789);
val fmt_0_d = Time.fmt 0 (Time.fromMicroseconds 444444444);
val fmt_0_u = Time.fmt 0 (Time.fromMicroseconds 555555555);
val fmt_1_n = Time.fmt 1 (Time.fromMicroseconds 123456789);
val fmt_1_d = Time.fmt 1 (Time.fromMicroseconds 444444444);
val fmt_1_u = Time.fmt 1 (Time.fromMicroseconds 555555555);
val fmt_2_n = Time.fmt 2 (Time.fromMicroseconds 123456789);
val fmt_2_d = Time.fmt 2 (Time.fromMicroseconds 444444444);
val fmt_2_u = Time.fmt 2 (Time.fromMicroseconds 555555555);
val fmt_3_n = Time.fmt 3 (Time.fromMicroseconds 123456789);
val fmt_3_d = Time.fmt 3 (Time.fromMicroseconds 444444444);
val fmt_3_u = Time.fmt 3 (Time.fromMicroseconds 555555555);
val fmt_4_n = Time.fmt 4 (Time.fromMicroseconds 123456789);
val fmt_4_d = Time.fmt 4 (Time.fromMicroseconds 444444444);
val fmt_4_u = Time.fmt 4 (Time.fromMicroseconds 555555555);
val fmt_5_n = Time.fmt 5 (Time.fromMicroseconds 123456789);
val fmt_5_d = Time.fmt 5 (Time.fromMicroseconds 444444444);
val fmt_5_u = Time.fmt 5 (Time.fromMicroseconds 555555555);
val fmt_6_n = Time.fmt 6 (Time.fromMicroseconds 123456789);
val fmt_6_d = Time.fmt 6 (Time.fromMicroseconds 444444444);
val fmt_6_u = Time.fmt 6 (Time.fromMicroseconds 555555555);
