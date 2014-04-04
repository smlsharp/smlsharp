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
  structure AL = SMLUnit.Assert.AssertLargeInt
  structure AT = SMLUnit.Assert.AssertTime
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
        val case_0 as () = assertEqualReal 0.0 (T.toReal (T.fromReal 0.0))
        val case_p as () = assertEqualReal 12.34 (T.toReal (T.fromReal 12.34))
        val case_m as () = assertEqualReal ~12.34 (T.toReal (T.fromReal ~12.34))
      in
        ()
      end

  fun fromToSeconds0001 () =
      let
        val conv = T.toSeconds o T.fromSeconds
        val case_0 as () = AL.assertEqualInt 0 (conv 0)
        val case_p as () = AL.assertEqualInt 123 (conv 123)
        val case_m as () = AL.assertEqualInt ~123 (conv ~123)

        val case_fromReal as () =
            AL.assertEqualInt 1 (T.toSeconds (T.fromReal 1.25))
      in
        ()
      end

  fun fromToMilliseconds0001 () =
      let
        val conv = T.toMilliseconds o T.fromMilliseconds
        val case_0 as () = AL.assertEqualInt 0 (conv 0)
        val case_p1 as () = AL.assertEqualInt 123 (conv 123)
        val case_p2 as () = AL.assertEqualInt 123456 (conv 123456)
        val case_p3 as () = AL.assertEqualInt 123456789 (conv 123456789)
        val case_m1 as () = AL.assertEqualInt ~123 (conv ~123)
        val case_m2 as () = AL.assertEqualInt ~123456 (conv ~123456)
        val case_m3 as () = AL.assertEqualInt ~123456789 (conv ~123456789)

        val case_fromReal as () =
            AL.assertEqualInt 1250 (T.toMilliseconds (T.fromReal 1.250000))
      in
        ()
      end

  fun fromToMicroseconds0001 () =
      let
        val conv = T.toMicroseconds o T.fromMicroseconds
        val case_0 as () = AL.assertEqualInt 0 (conv 0)
        val case_p1 as () = AL.assertEqualInt 123 (conv 123)
        val case_p2 as () = AL.assertEqualInt 123456 (conv 123456)
        val case_p3 as () = AL.assertEqualInt 123456789 (conv 123456789)
        val case_m1 as () = AL.assertEqualInt ~123 (conv ~123)
        val case_m2 as () = AL.assertEqualInt ~123456 (conv ~123456)
        val case_m3 as () = AL.assertEqualInt ~123456789 (conv ~123456789)

        val case_fromReal as () =
            AL.assertEqualInt 1250000 (T.toMicroseconds (T.fromReal 1.25))
      in
        ()
      end

  fun fromToNanoseconds0001 () =
      let
        val conv = T.toNanoseconds o T.fromNanoseconds
        val case_0 as () = AL.assertEqualInt 0 (conv 0)
        val case_p1 as () = AL.assertEqualInt 123 (conv 123)
        val case_p2 as () = AL.assertEqualInt 123456 (conv 123456)
        val case_p3 as () = AL.assertEqualInt 123456789 (conv 123456789)
        val case_m1 as () = AL.assertEqualInt ~123 (conv ~123)
        val case_m2 as () = AL.assertEqualInt ~123456 (conv ~123456)
        val case_m3 as () = AL.assertEqualInt ~123456789 (conv ~123456789)

        val case_fromReal as () =
            AL.assertEqualInt 1250000000 (T.toNanoseconds (T.fromReal 1.25))
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
        val case_00_00 as () = test (0, 0) 0
        val case_11_22 as () = test (1000001, 2000002) 3000003
        (* no round up *)
        val case_NroundUp as () = test (1500000, 2499999) 3999999
        (* round up *)
        val case_roundUp as () = test (1500000, 2500000) 4000000
      in
        ()
      end

  fun sub0001 () =
      let
        val test = test T.-
        val case_00_00 as () = test (0, 0) 0
        val case_11_22 as () = test (2000002, 1000001) 1000001
        (* no round down *)
        val case_NroundDown as () = test (2500000, 1499999) 1000001
        (* no round down *)
        val case_NroundDown as () = test (2500000, 1500000) 1000000
        (* round down *)
        val case_roundDown as () = test (2499999, 1500000) 999999
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
        val case_E_0 as () = test (0, 0) EQUAL
        val case_E_p as () = test (1000123, 1000123) EQUAL
        val case_L_0 as () = test (0, 1000000) LESS
        val case_L_1 as () = test (1000000, 1000001) LESS
        val case_G_0 as () = test (1000000, 0) GREATER
        val case_G_1 as () = test (1000001, 1000000) GREATER
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
        val case_0 as () = test (0, 0) FTTF
        val case_t1 as () = test (0, 1000000) TTFF
        val case_t2 as () = test (0, 1) TTFF
        val case_t3 as () = test (2, 1000000) TTFF
        val case_f1 as () = test (1000000, 0) FFTT
        val case_f2 as () = test (1000000, 2) FFTT
        val case_f3 as () = test (1000002, 1000002) FTTF
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
        val case_0_n as () = test 0 (T.fromMicroseconds 123456789) "123"
        val case_0_d as () = test 0 (T.fromMicroseconds 444444444) "444"
        val case_0_u as () = test 0 (T.fromMicroseconds 555555555) "556"
        val case_1_n as () = test 1 (T.fromMicroseconds 123456789) "123.5"
        val case_1_d as () = test 1 (T.fromMicroseconds 444444444) "444.4"
        val case_1_u as () = test 1 (T.fromMicroseconds 555555555) "555.6"
        val case_2_n as () = test 2 (T.fromMicroseconds 123456789) "123.46"
        val case_2_d as () = test 2 (T.fromMicroseconds 444444444) "444.44"
        val case_2_u as () = test 2 (T.fromMicroseconds 555555555) "555.56"
        val case_3_n as () = test 3 (T.fromMicroseconds 123456789) "123.457"
        val case_3_d as () = test 3 (T.fromMicroseconds 444444444) "444.444"
        val case_3_u as () = test 3 (T.fromMicroseconds 555555555) "555.556"
        val case_4_n as () = test 4 (T.fromMicroseconds 123456789) "123.4568"
        val case_4_d as () = test 4 (T.fromMicroseconds 444444444) "444.4444"
        val case_4_u as () = test 4 (T.fromMicroseconds 555555555) "555.5556"
        val case_5_n as () = test 5 (T.fromMicroseconds 123456789) "123.45679"
        val case_5_d as () = test 5 (T.fromMicroseconds 444444444) "444.44444"
        val case_5_u as () = test 5 (T.fromMicroseconds 555555555) "555.55556"
        val case_6_n as () = test 6 (T.fromMicroseconds 123456789) "123.456789"
        val case_6_d as () = test 6 (T.fromMicroseconds 444444444) "444.444444"
        val case_6_u as () = test 6 (T.fromMicroseconds 555555555) "555.555555"
      in
        ()
      end
  end (* local *)
  fun fmt1001 () =
      (T.fmt ~1 T.zeroTime; fail "Size expected.")
      handle General.Size => ()
        
  fun toString0001 () =
      let
        val case_0 as () = assertEqualString "0.000" (T.toString T.zeroTime)
        val case_1 as () = assertEqualString "123.457" (T.toString (T.fromMicroseconds 123456789))
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
        val case_0 as () = test "0" (SOME (T.zeroTime, []))
        (* no sign, 1 number, no fraction *)
        val case_n_1_0 as () = test "1" (SOME (T.fromSeconds 1, []))
        val case_n_1_1 as () = test "1.2" (SOME (T.fromMilliseconds 1200, []))
        val case_n_3_3 as () = test "123.321" (SOME (T.fromMilliseconds 123321, []))
        val case_n_0_1 as () = test ".1" (SOME (T.fromMilliseconds 100, []))
        val case_n_0_3 as () = test ".321" (SOME (T.fromMilliseconds 321, []))
        val case_p_3_3 as () = test "+123.321" (SOME (T.fromMilliseconds 123321, []))
        val case_t_3_3 as () = test "~123.321" (SOME (T.fromMilliseconds ~123321, []))
        val case_m_3_3 as () = test "-123.321" (SOME (T.fromMilliseconds ~123321, []))
        val case_initws as () = test " \f\n\r\t\v1.2" (SOME (T.fromMilliseconds 1200, []))
        val case_trailer as () = test "1.2abc" (SOME (T.fromMilliseconds 1200, [#"a", #"b", #"c"]))
        val case_empty as () = test "" NONE
        val case_NONE as () = test "abc" NONE
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
        val case_0 as () = test "0" (SOME T.zeroTime)
        (* no sign, 1 number, no fraction *)
        val case_n_1_0 as () = test "1" (SOME (T.fromSeconds 1))
        val case_n_1_1 as () = test "1.2" (SOME (T.fromMilliseconds 1200))
        val case_n_3_3 as () = test "123.321" (SOME (T.fromMilliseconds 123321))
        val case_n_0_1 as () = test ".1" (SOME (T.fromMilliseconds 100))
        val case_n_0_3 as () = test ".321" (SOME (T.fromMilliseconds 321))
        val case_p_3_3 as () = test "+123.321" (SOME (T.fromMilliseconds 123321))
        val case_t_3_3 as () = test "~123.321" (SOME (T.fromMilliseconds ~123321))
        val case_m_3_3 as () = test "-123.321" (SOME (T.fromMilliseconds ~123321))

        val case_initws as () = test " \f\n\r\t\v1.2" (SOME (T.fromMilliseconds 1200))
        val case_trailer as () = test "1.2abc" (SOME (T.fromMilliseconds 1200))
        val case_empty as () = test "" NONE
        val case_NONE as () = test "abc" NONE
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
        ("fmt1001", fmt1001),
        ("toString0001", toString0001),
        ("scan0001", scan0001),
        ("fromString0001", fromString0001)
      ]

  (************************************************************)

end