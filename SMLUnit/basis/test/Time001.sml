(**
 * test cases for Time structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure Time001 =
struct

  (************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test
  structure AL = AssertLargeInt
  structure AT = AssertTime
  open A
  open AT

  structure T = Time

  (************************************************************)

  val assertEqual4Bool =
      assertEqual4Tuple
          (assertEqualBool, assertEqualBool, assertEqualBool, assertEqualBool)

  val assertEqualTimeOption = assertEqualOption assertEqualTime

  val assertEqualTimeCListOption = 
      assertEqualOption
          (assertEqual2Tuple (assertEqualTime, assertEqualCharList))

  (********************)

  fun zeroTime0001 () =
      (assertEqualTime (T.fromReal 0.0) T.zeroTime; ())

  fun fromToReal0001 () =
      let
        val fromToReal_0 = assertEqualReal 0.0 (T.toReal (T.fromReal 0.0))
        val fromToReal_p = assertEqualReal 12.34 (T.toReal (T.fromReal 12.34))
        val fromToReal_m = assertEqualReal ~12.34 (T.toReal (T.fromReal ~12.34))
      in
        ()
      end

  fun fromToSeconds0001 () =
      let
        val conv = T.toSeconds o T.fromSeconds
        val seconds_0 = AL.assertEqualInt 0 (conv 0)
        val seconds_p = AL.assertEqualInt 123 (conv 123)
        val sconds_m = AL.assertEqualInt ~123 (conv ~123)

        val seconds_fromReal =
            AL.assertEqualInt 2 (T.toSeconds (T.fromReal 2.01))
      in
        ()
      end

  fun fromToMilliseconds0001 () =
      let
        val conv = T.toMilliseconds o T.fromMilliseconds
        val milliseconds_0 = AL.assertEqualInt 0 (conv 0)
        val milliseconds_p1 = AL.assertEqualInt 123 (conv 123)
        val milliseconds_p2 = AL.assertEqualInt 123456 (conv 123456)
        val milliseconds_p3 = AL.assertEqualInt 123456789 (conv 123456789)
        val milliseconds_m1 = AL.assertEqualInt ~123 (conv ~123)
        val milliseconds_m2 = AL.assertEqualInt ~123456 (conv ~123456)
        val milliseconds_m3 = AL.assertEqualInt ~123456789 (conv ~123456789)

        val milliseconds_fromReal =
            AL.assertEqualInt 2010 (T.toMilliseconds (T.fromReal 2.010000))
      in
        ()
      end

  fun fromToMicroseconds0001 () =
      let
        val conv = T.toMicroseconds o T.fromMicroseconds
        val microseconds_0 = AL.assertEqualInt 0 (conv 0)
        val microseconds_p1 = AL.assertEqualInt 123 (conv 123)
        val microseconds_p2 = AL.assertEqualInt 123456 (conv 123456)
        val microseconds_p3 = AL.assertEqualInt 123456789 (conv 123456789)
        val microseconds_m1 = AL.assertEqualInt ~123 (conv ~123)
        val microseconds_m2 = AL.assertEqualInt ~123456 (conv ~123456)
        val microseconds_m3 = AL.assertEqualInt ~123456789 (conv ~123456789)

        val microseconds_fromReal =
            AL.assertEqualInt 2010000 (T.toMicroseconds (T.fromReal 2.01))
      in
        ()
      end

  fun fromToNanoseconds0001 () =
      let
        val conv = T.toNanoseconds o T.fromNanoseconds
        val toNanoseconds_0 = AL.assertEqualInt 0 (conv 0)
        val toNanoseconds_p1 = AL.assertEqualInt 123 (conv 123)
        val toNanoseconds_p2 = AL.assertEqualInt 123456 (conv 123456)
        val toNanoseconds_p3 = AL.assertEqualInt 123456789 (conv 123456789)
        val toNanoseconds_m1 = AL.assertEqualInt ~123 (conv ~123)
        val toNanoseconds_m2 = AL.assertEqualInt ~123456 (conv ~123456)
        val toNanoseconds_m3 = AL.assertEqualInt ~123456789 (conv ~123456789)

        val toNanoseconds_fromReal =
            AL.assertEqualInt 2010000000 (T.toNanoseconds (T.fromReal 2.01))
      in
        ()
      end

  local
    fun test operator (usec1, usec2) expected =
        let
          val t1 = T.fromMicroseconds usec1
          val t2 = T.fromMicroseconds usec2
        in
          assertEqualTime (T.fromMicroseconds expected) (operator (t1, t2))
        end
  in
  fun add0001 () =
      let
        val test = test T.+
        val add_00_00 = test (0, 0) 0
        val add_11_22 = test (1000001, 2000002) 3000003
        (* no round up *)
        val add_NroundUp = test (1500000, 2499999) 3999999
        (* round up *)
        val add_roundUp = test (1500000, 2500000) 4000000
      in
        ()
      end

  fun sub0001 () =
      let
        val test = test T.-
        val sub_00_00 = test (0, 0) 0
        val sub_11_22 = test (2000002, 1000001) 1000001
        (* no round down *)
        val sub_NroundDown = test (2500000, 1499999) 1000001
        (* no round down *)
        val sub_NroundDown = test (2500000, 1500000) 1000000
        (* round down *)
        val sub_roundDown = test (2499999, 1500000) 999999
      in
        ()
      end
  end (* local *)

  local
    fun test (usec1, usec2) expected =
        let
          val t1 = T.fromMicroseconds usec1
          val t2 = T.fromMicroseconds usec2
        in
          assertEqualOrder expected (T.compare (t1, t2))
        end
  in
  fun compare0001 () =
      let
        val compare_E_0 = test (0, 0) EQUAL
        val compare_E_p = test (1000123, 1000123) EQUAL
        val compare_L_0 = test (0, 1000000) LESS
        val compare_L_1 = test (1000000, 1000001) LESS
        val compare_G_0 = test (1000000, 0) GREATER
        val compare_G_1 = test (1000001, 1000000) GREATER
      in
        ()
      end
  end (* local *)

  local
    val TTTT = (true, true, true, true)
    val TTFF = (true, true, false, false)
    val TFTF = (true, false, true, false)
    val FTTT = (false, true, true, true)
    val FTTF = (false, true, true, false)
    val FTFF = (false, true, false, false)
    val FFTT = (false, false, true, true)
    val FFFF = (false, false, false, false)
    fun test (usec1, usec2) expected =
        let
          val t1 = T.fromMicroseconds usec1
          val t2 = T.fromMicroseconds usec2
          val args = (t1, t2)
        in
          assertEqual4Bool expected (T.< args, T.<= args, T.>= args, T.> args)
        end
  in
  fun binComp0001 () =
      let
        val binComp_0 = test (0, 0) FTTF
        val binComp_t1 = test (0, 1000000) TTFF
        val binComp_t2 = test (0, 1) TTFF
        val binComp_t3 = test (2, 1000000) TTFF
        val binComp_f1 = test (1000000, 0) FFTT
        val binComp_f2 = test (1000000, 2) FFTT
        val binComp_f3 = test (1000002, 1000002) FTTF
      in
        ()
      end
  end

  fun now0001 () = ()

  local
    fun test arg1 arg2 expected =
        assertEqualString expected (T.fmt arg1 arg2)
  in
  fun fmt0001 () =
      let
        val fmt_0_n = test 0 (T.fromMicroseconds 123456789) "123"
        val fmt_0_d = test 0 (T.fromMicroseconds 444444444) "444"
        val fmt_0_u = test 0 (T.fromMicroseconds 555555555) "556"
        val fmt_1_n = test 1 (T.fromMicroseconds 123456789) "123.5"
        val fmt_1_d = test 1 (T.fromMicroseconds 444444444) "444.4"
        val fmt_1_u = test 1 (T.fromMicroseconds 555555555) "555.6"
        val fmt_2_n = test 2 (T.fromMicroseconds 123456789) "123.46"
        val fmt_2_d = test 2 (T.fromMicroseconds 444444444) "444.44"
        val fmt_2_u = test 2 (T.fromMicroseconds 555555555) "555.56"
        val fmt_3_n = test 3 (T.fromMicroseconds 123456789) "123.457"
        val fmt_3_d = test 3 (T.fromMicroseconds 444444444) "444.444"
        val fmt_3_u = test 3 (T.fromMicroseconds 555555555) "555.556"
        val fmt_4_n = test 4 (T.fromMicroseconds 123456789) "123.4568"
        val fmt_4_d = test 4 (T.fromMicroseconds 444444444) "444.4444"
        val fmt_4_u = test 4 (T.fromMicroseconds 555555555) "555.5556"
        val fmt_5_n = test 5 (T.fromMicroseconds 123456789) "123.45679"
        val fmt_5_d = test 5 (T.fromMicroseconds 444444444) "444.44444"
        val fmt_5_u = test 5 (T.fromMicroseconds 555555555) "555.55556"
        val fmt_6_n = test 6 (T.fromMicroseconds 123456789) "123.456789"
        val fmt_6_d = test 6 (T.fromMicroseconds 444444444) "444.444444"
        val fmt_6_u = test 6 (T.fromMicroseconds 555555555) "555.555555"
      in
        ()
      end
  end (* local *)
        
  fun toString0001 () =
      let
        val toString_0 = assertEqualString "0.000" (T.toString T.zeroTime)
        val toString_1 = assertEqualString "123.457" (T.toString (T.fromMicroseconds 123456789))
      in
        ()
      end

  local
    fun test arg expected =
        assertEqualTimeCListOption
            expected
            (Time.scan List.getItem (explode arg))
  in
  fun scan0001 () = 
      let
        val scan_0 = test "0" (SOME (T.zeroTime, []))
        (* no sign, 1 number, no fraction *)
        val scan_n_1_0 = test "1" (SOME (T.fromSeconds 1, []))
        val scan_n_1_1 = test "1.2" (SOME (T.fromMilliseconds 1200, []))
        val scan_n_3_3 = test "123.321" (SOME (T.fromMilliseconds 123321, []))
        val scan_n_0_1 = test ".1" (SOME (T.fromMilliseconds 100, []))
        val scan_n_0_3 = test ".321" (SOME (T.fromMilliseconds 321, []))
        val scan_p_3_3 = test "+123.321" (SOME (T.fromMilliseconds 123321, []))
        val scan_t_3_3 = test "~123.321" (SOME (T.fromMilliseconds ~123321, []))
        val scan_m_3_3 = test "-123.321" (SOME (T.fromMilliseconds ~123321, []))
        val scan_initws = test " \f\n\r\t\v1.2" (SOME (T.fromMilliseconds 1200, []))
        val scan_trailer = test "1.2abc" (SOME (T.fromMilliseconds 1200, [#"a", #"b", #"c"]))
        val scan_empty = test "" NONE
        val scan_NONE = test "abc" NONE
      in
        ()
      end
  end (* local *)

  local
    fun test arg expected =
        assertEqualTimeOption expected (T.fromString arg)
  in
  fun fromString0001 () =
      let
        val fromString_0 = test "0" (SOME T.zeroTime)
        (* no sign, 1 number, no fraction *)
        val fromString_n_1_0 = test "1" (SOME (T.fromSeconds 1))
        val fromString_n_1_1 = test "1.2" (SOME (T.fromMilliseconds 1200))
        val fromString_n_3_3 = test "123.321" (SOME (T.fromMilliseconds 123321))
        val fromString_n_0_1 = test ".1" (SOME (T.fromMilliseconds 100))
        val fromString_n_0_3 = test ".321" (SOME (T.fromMilliseconds 321))
        val fromString_p_3_3 = test "+123.321" (SOME (T.fromMilliseconds 123321))
        val fromString_t_3_3 = test "~123.321" (SOME (T.fromMilliseconds ~123321))
        val fromString_m_3_3 = test "-123.321" (SOME (T.fromMilliseconds ~123321))

        val fromString_initws = test " \f\n\r\t\v1.2" (SOME (T.fromMilliseconds 1200))
        val fromString_trailer = test "1.2abc" (SOME (T.fromMilliseconds 1200))
        val fromString_empty = test "" NONE
        val fromString_NONE = test "abc" NONE
      in
        ()
      end
  end (* local *)

  (****************************************)

  fun suite () =
      SMLUnit.Test.labelTests
      [
        ("zeroTime0001", zeroTime0001),
        ("fromToReal0001", fromToReal0001),
        ("fromToSeconds0001", fromToSeconds0001),
        ("fromToMilliseconds0001", fromToMilliseconds0001),
        ("fromToMicroseconds0001", fromToMicroseconds0001),
        ("fromToNanoseconds0001", fromToNanoseconds0001),
        ("add0001", add0001),
        ("sub0001", sub0001),
        ("compare0001", compare0001),
        ("binComp0001", binComp0001),
        ("now0001", now0001),
        ("fmt0001", fmt0001),
        ("toString0001", toString0001),
        ("scan0001", scan0001),
        ("fromString0001", fromString0001)
      ]

  (************************************************************)

end