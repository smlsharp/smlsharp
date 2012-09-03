(**
 * test cases for Date.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure Date001 =
struct

  (************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test
  structure AD = SMLUnit.Assert.AssertDate
  structure AT = SMLUnit.Assert.AssertTime
  open A
  open AD

  structure D = Date

  (************************************************************)

  val assertEqualTimeOption = assertEqualOption AT.assertEqualTime

  val assertEqualDateOption = assertEqualOption assertEqualDate

  val assertEqualDateCListOption = 
      assertEqualOption
          (assertEqual2Tuple(assertEqualDate, assertEqualCharList))

  fun makeDate (year, month, day, hour, minute, second, offset) =
      {
        year = year,
        month = month,
        day = day,
        hour = hour,
        minute = minute,
        second = second,
        offset = offset
      }

  (********************)

  fun date_min () =
      let
        val d = D.date (makeDate (1900, D.Jan, 1, 0, 0, 0, NONE))
        val _ = assertEqualInt 1900 (D.year d)
        val _ = assertEqualMonth D.Jan (D.month d)
        val _ = assertEqualInt 1 (D.day d)
        val _ = assertEqualInt 0 (D.hour d)
        val _ = assertEqualInt 0 (D.minute d)
        val _ = assertEqualInt 0 (D.second d)
        val _ = assertEqualTimeOption NONE (D.offset d)
      in () end

  fun date_max () =
      let
        (* specify 2037 to avoid year 2038 problem.
         * SML/NJ 110.72 raises Overflow if the specified date is beyond
         * 03:14:07 UTC, 19 January 2038.
         * Assume UTC+9 (= Japan time zone).
         *   Date.date{year=2038, month=Date.Jan, day=19, hour=12, minute=14,
         *        second=8, offset=SOME Time.zeroTime};
         * Moreover, SML/NJ crashes if offset is specified NONE.
         *   Date.date{year=2038, month=Date.Jan, day=19, hour=12, minute=14,
         *        second=8, offset=NONE};
         *)
        val d = D.date (makeDate (2037, D.Dec, 31, 23, 59, 59, NONE))
        val _ = assertEqualInt 2037 (D.year d)
        val _ = assertEqualMonth D.Dec (D.month d)
        val _ = assertEqualInt 31 (D.day d)
        val _ = assertEqualInt 23 (D.hour d)
        val _ = assertEqualInt 59 (D.minute d)
        val _ = assertEqualInt 59 (D.second d)
        val _ = assertEqualTimeOption NONE (D.offset d)
      in () end

  fun date_carry () =
      let
        val d = D.date (makeDate (9999, D.Dec, 31, 23, 59, 60, NONE))
        val _ = assertEqualInt 10000 (D.year d)
        val _ = assertEqualMonth D.Jan (D.month d)
        val _ = assertEqualInt 1 (D.day d)
        val _ = assertEqualInt 0 (D.hour d)
        val _ = assertEqualInt 0 (D.minute d)
        val _ = assertEqualInt 0 (D.second d)
        val _ = assertEqualTimeOption NONE (D.offset d)
      in () end

  fun date_borrow () =
      let
        val d = D.date (makeDate (0, D.Jan, 1, 0, 0, ~1, NONE))
        val _ = assertEqualInt ~1 (D.year d)
        val _ = assertEqualMonth D.Dec (D.month d)
        val _ = assertEqualInt 31 (D.day d)
        val _ = assertEqualInt 23 (D.hour d)
        val _ = assertEqualInt 59 (D.minute d)
        val _ = assertEqualInt 59 (D.second d)
        val _ = assertEqualTimeOption NONE (D.offset d)
      in () end

  fun date_offset_0 () =
      let
        val d = D.date (makeDate (0, D.Jan, 1, 0, 0, 0, SOME(Time.zeroTime)))
        val _ = assertEqualInt 0 (D.year d)
        val _ = assertEqualMonth D.Jan (D.month d)
        val _ = assertEqualInt 1 (D.day d)
        val _ = assertEqualInt 0 (D.hour d)
        val _ = assertEqualInt 0 (D.minute d)
        val _ = assertEqualInt 0 (D.second d)
        val _ = assertEqualTimeOption (SOME(Time.zeroTime)) (D.offset d)
      in () end

  fun date_offset_1sec () =
      let
        val offset = Time.fromSeconds 1
        val d = D.date (makeDate (0, D.Jan, 1, 0, 0, 0, SOME offset))
        val _ = assertEqualInt 0 (D.year d)
        val _ = assertEqualMonth D.Jan (D.month d)
        val _ = assertEqualInt 1 (D.day d)
        val _ = assertEqualInt 0 (D.hour d)
        val _ = assertEqualInt 0 (D.minute d)
        val _ = assertEqualInt 0 (D.second d)
        val _ = assertEqualTimeOption (SOME offset) (D.offset d)
      in () end

  fun date_offset_1hour () =
      let
        val offset = Time.fromSeconds (60 * 60 * 1)
        val d = D.date (makeDate (0, D.Jan, 1, 0, 0, 0, SOME offset))
        val _ = assertEqualInt 0 (D.year d)
        val _ = assertEqualMonth D.Jan (D.month d)
        val _ = assertEqualInt 1 (D.day d)
        val _ = assertEqualInt 0 (D.hour d)
        val _ = assertEqualInt 0 (D.minute d)
        val _ = assertEqualInt 0 (D.second d)
        val _ = assertEqualTimeOption (SOME offset) (D.offset d)
      in () end

  fun date_offset_over24h () =
      let
        (* offset = 24 hour plus 1 second *)
        val offset = Time.fromSeconds (60 * 60 * 24 + 1)
        val d = D.date (makeDate (0, D.Jan, 1, 0, 0, 0, SOME offset))
        val _ = assertEqualInt 0 (D.year d)
        val _ = assertEqualMonth D.Jan (D.month d)
        val _ = assertEqualInt 2 (D.day d)
        val _ = assertEqualInt 0 (D.hour d)
        val _ = assertEqualInt 0 (D.minute d)
        val _ = assertEqualInt 0 (D.second d)
        val _ = assertEqualTimeOption (SOME(Time.fromSeconds 1)) (D.offset d)
      in () end

  fun date_leap_001 () =
      let
        (* Because 1987 is not leap year, Feb 29 is canonicalized to Mar 1. *)
        val d = D.date (makeDate (1987, D.Feb, 29, 0, 0, 0, NONE))
        val _ = assertEqualInt 1987 (D.year d)
        val _ = assertEqualMonth D.Mar (D.month d)
        val _ = assertEqualInt 1 (D.day d)
        val _ = assertEqualInt 0 (D.hour d)
        val _ = assertEqualInt 0 (D.minute d)
        val _ = assertEqualInt 0 (D.second d)
        val _ = assertEqualTimeOption NONE (D.offset d)
      in () end

  fun date_leap_002 () =
      let
        (* Because 1988 is a leap year, Feb 29 is unchanged. *)
        val d = D.date (makeDate (1988, D.Feb, 29, 0, 0, 0, NONE))
        val _ = assertEqualInt 1988 (D.year d)
        val _ = assertEqualMonth D.Feb (D.month d)
        val _ = assertEqualInt 29 (D.day d)
        val _ = assertEqualInt 0 (D.hour d)
        val _ = assertEqualInt 0 (D.minute d)
        val _ = assertEqualInt 0 (D.second d)
        val _ = assertEqualTimeOption NONE (D.offset d)
      in () end

  fun date_leap_003 () =
      let
        (* Because 1900 is NOT a leap year,
         * Feb 29 is canonicalized to Mar 1. *)
        val d = D.date (makeDate (1900, D.Feb, 29, 0, 0, 0, NONE))
        val _ = assertEqualInt 1900 (D.year d)
        val _ = assertEqualMonth D.Mar (D.month d)
        val _ = assertEqualInt 1 (D.day d)
        val _ = assertEqualInt 0 (D.hour d)
        val _ = assertEqualInt 0 (D.minute d)
        val _ = assertEqualInt 0 (D.second d)
        val _ = assertEqualTimeOption NONE (D.offset d)
      in () end

  fun date_leap_004 () =
      let
        (* Because 2000 is a leap year, Feb 29 is unchanged. *)
        val d = D.date (makeDate (2000, D.Feb, 29, 0, 0, 0, NONE))
        val _ = assertEqualInt 2000 (D.year d)
        val _ = assertEqualMonth D.Feb (D.month d)
        val _ = assertEqualInt 29 (D.day d)
        val _ = assertEqualInt 0 (D.hour d)
        val _ = assertEqualInt 0 (D.minute d)
        val _ = assertEqualInt 0 (D.second d)
        val _ = assertEqualTimeOption NONE (D.offset d)
      in () end

  (********************)

  fun year0001 () = () (* omit because tested in above date_*. *)

  (********************)

  fun month0001 () = () (* omit because tested in above date_*. *)

  (********************)

  fun day0001 () = () (* omit because tested in above date_*. *)

  (********************)

  fun hour0001 () = () (* omit because tested in above date_*. *)

  (********************)

  fun minute0001 () = () (* omit because tested in above date_*. *)

  (********************)

  fun second0001 () = () (* omit because tested in above date_*. *)

  (********************)

  fun weekDay0001 () =
      let
        val d = D.date (makeDate (2001, D.Jan, 1, 0, 0, 0, NONE))
        val wd = D.weekDay d
        val _ = assertEqualWeekday D.Mon wd
      in () end

  (********************)

  fun yearDay0001 () =
      let
        val d1 = D.date (makeDate (2001, D.Jan, 1, 0, 0, 0, NONE))
        val yd1 = D.yearDay d1
        val _ = assertEqualInt 0 yd1

        val d2 = D.date (makeDate (2001, D.Dec, 31, 0, 0, 0, NONE))
        val yd2 = D.yearDay d2
        val _ = assertEqualInt 364 yd2
      in () end

  (********************)

  fun offset0001 () = () (* omit because tested in above date_*. *)

  (********************)

  fun isDst0001 () =
      (* FIXME: How can we test isDst ? *)
      ()

  (********************)

  fun localOffset0001 () =
      let
        val offset = D.localOffset ()
        val d1 = D.date (makeDate (2001, D.Jan, 1, 0, 0, 0, NONE))
        val d2 = D.date (makeDate (2001, D.Jan, 1, 0, 0, 0, SOME offset))
        val _ = AT.assertEqualTime (D.toTime d1) (D.toTime d2)
      in () end

  (********************)

  fun fromToTime_local () =
      let
        (* d is in local time zone *)
        val d = D.date (makeDate (2001, D.Jan, 1, 0, 0, 0, NONE))
        val t = D.toTime d

        (* dl is in local time zone *)
        val dl = D.fromTimeLocal t
        val _ = assertEqualTimeOption NONE (D.offset dl)
        val _ = assertEqualDate d dl
      in () end

  fun fromToTime_universal () =
      let
        (* d is in local time zone *)
        val d = D.date (makeDate (2001, D.Jan, 1, 0, 0, 0, SOME Time.zeroTime))
        val t = D.toTime d

        (* du is in universal time zone *)
        val du = D.fromTimeUniv t
        val _ = assertEqualTimeOption (SOME Time.zeroTime) (D.offset du)
        val _ = assertEqualDate d du
      in () end

  (********************)

  local
    fun test (arg1, arg2) expected =
        let
          val d1 = D.date (makeDate arg1)
          val d2 = D.date (makeDate arg2)
        in
          assertEqualOrder expected (D.compare (d1, d2))
        end
  in
  fun compare0001 () =
      let
        val compare_eq =
            test
                (
                  (2001, D.Jun, 6, 15, 30, 30, NONE),
                  (2001, D.Jun, 6, 15, 30, 30, NONE)
                )
                EQUAL
        val compare_y_lt =
            test
                (
                  (2001, D.Jun, 6, 15, 30, 30, NONE),
                  (2002, D.Jan, 6, 15, 30, 30, NONE)
                )
                LESS
        val compare_y_gt =
            test
                (
                  (2002, D.Jan, 6, 15, 30, 30, NONE),
                  (2001, D.Jun, 6, 15, 30, 30, NONE)
                )
                GREATER

        val compare_m_lt =
            test
                (
                  (2001, D.Jan, 7, 15, 30, 30, NONE),
                  (2001, D.Jun, 6, 15, 30, 30, NONE)
                )
                LESS
        val compare_m_gt =
            test
                (
                  (2001, D.Jun, 6, 15, 30, 30, NONE),
                  (2001, D.Jan, 7, 15, 30, 30, NONE)
                )
                GREATER
        val compare_d_lt =
            test
                (
                  (2001, D.Jun, 5, 20, 30, 30, NONE),
                  (2001, D.Jun, 6, 15, 30, 30, NONE)
                )
                LESS
        val compare_d_gt =
            test
                (
                  (2001, D.Jun, 6, 15, 30, 30, NONE),
                  (2001, D.Jun, 5, 20, 30, 30, NONE)
                )
                GREATER
        val compare_h_lt =
            test
                (
                  (2001, D.Jun, 6, 10, 45, 30, NONE),
                  (2001, D.Jun, 6, 15, 30, 30, NONE)
                )
                LESS
        val compare_h_gt =
            test
                (
                  (2001, D.Jun, 6, 15, 30, 30, NONE),
                  (2001, D.Jun, 6, 10, 45, 30, NONE)
                )
                GREATER
        val compare_m_lt =
            test
                (
                  (2001, D.Jun, 6, 15, 15, 45, NONE),
                  (2001, D.Jun, 6, 15, 30, 30, NONE)
                )
                LESS
        val compare_m_gt =
            test
                (
                  (2001, D.Jun, 6, 15, 30, 30, NONE),
                  (2001, D.Jun, 6, 15, 15, 45, NONE)
                )
                GREATER
        val compare_s_lt =
            test
                (
                  (2001, D.Jun, 6, 15, 30, 15, NONE),
                  (2001, D.Jun, 6, 15, 30, 30, NONE)
                )
                LESS
        val compare_gt =
            test
                (
                  (2001, D.Jun, 6, 15, 30, 30, NONE),
                  (2001, D.Jun, 6, 15, 30, 15, NONE)
                )
                GREATER
      in () end

  (* check that compare ignors offset field. *)
  fun compare0002 () =
      let
        val compare_eq =
            test
                (
                  (2001, D.Jun, 6, 15, 30, 30, SOME(Time.fromSeconds 100)),
                  (2001, D.Jun, 6, 15, 30, 30, SOME(Time.fromSeconds ~100))
                )
                EQUAL
        val compare_lt_1 =
            test
                (
                  (2001, D.Jun, 6, 15, 30, 15, SOME(Time.fromSeconds 100)),
                  (2001, D.Jun, 6, 15, 30, 30, SOME(Time.fromSeconds ~100))
                )
                LESS
        val compare_lt_2 =
            test
                (
                  (2001, D.Jun, 6, 15, 30, 15, SOME(Time.fromSeconds ~100)),
                  (2001, D.Jun, 6, 15, 30, 30, SOME(Time.fromSeconds 100))
                )
                LESS
      in () end
  end (* local *)

  (********************)

  (* Date.fmt accepts following formats:
   * %a  locale's abbreviated weekday name  
   * %A  locale's full weekday name  
   * %b  locale's abbreviated month name  
   * %B  locale's full month name  
   * %c  locale's date and time representation (e.g., "Dec 2 06:55:15 1979")  
   * %d  day of month [01-31]  
   * %H  hour [00-23]  
   * %I  hour [01-12]  
   * %j  day of year [001-366]  
   * %m  month number [01-12]  
   * %M  minutes [00-59]  
   * %p  locale's equivalent of the AM/PM designation  
   * %S  seconds [00-61]  
   * %U  week number of year [00-53], with the first Sunday as the first day
   *    of week 01  
   * %w  day of week [0-6], with 0 representing Sunday  
   * %W  week number of year [00-53], with the first Monday as the first day
   *    of week 01  
   * %x  locale's appropriate date representation  
   * %X  locale's appropriate time representation  
   * %y  year of century [00-99]  
   * %Y  year including century (e.g., 1997)  
   * %Z  time zone name or abbreviation, or the empty string if no time zone
   *    information exists  
   * %%  the percent character  
   * %c  the character c, if c is not one of the format characters listed above
   *)
  local
    fun test arg1 arg2 expected = assertEqualString expected (D.fmt arg1 arg2)
  in
  fun fmt0001 () =
      let
        val d1 = D.date (makeDate (2001, D.Jan, 2, 3, 4, 5, NONE))
        val d2 = D.date (makeDate (1999, D.Dec, 31, 23, 34, 45, NONE))
        val fmt_d_1 = test "%d" d1 "02"
        val fmt_d_2 = test "%d" d2 "31"
        val fmt_H_1 = test "%H" d1 "03"
        val fmt_H_2 = test "%H" d2 "23"
        val fmt_I_1 = test "%I" d1 "03"
        val fmt_I_2 = test "%I" d2 "11"
        val fmt_j_1 = test "%j" d1 "002"
        val fmt_j_2 = test "%j" d2 "365"
        val fmt_m_1 = test "%m" d1 "01"
        val fmt_m_2 = test "%m" d2 "12"
        val fmt_M_1 = test "%M" d1 "04"
        val fmt_M_2 = test "%M" d2 "34"
        val fmt_S_1 = test "%S" d1 "05"
        val fmt_S_2 = test "%S" d2 "45"
        val fmt_U_1 = test "%U" d1 "00" (* First Sunday is 2001/Jan/7. *)
        val fmt_U_2 = test "%U" d2 "52"
        val fmt_w_1 = test "%w" d1 "2" (* 2001/Jan/2 is Tuesday. *)
        val fmt_w_2 = test "%w" d2 "5" (* 1999/Dec/31 is Friday. *)
        val fmt_W_1 = test "%W" d1 "01" (* First Monday is 2001/Jan/1. *)
        val fmt_W_2 = test "%W" d2 "52"
        val fmt_y_1 = test "%y" d1 "01"
        val fmt_y_2 = test "%y" d2 "99"
        val fmt_Y_1 = test "%Y" d1 "2001"
        val fmt_Y_2 = test "%Y" d2 "1999"
(*
        val fmt_percent = test "%%" d1 "%" (* SML/NJ 110.72 crashes here. *)
*)
        val fmt_other = test "%e" d1 "e"
      in () end
  end

  (********************)

  fun toString0001 () =
      let
        val d = D.date (makeDate (2001, D.Jan, 2, 3, 4, 5, NONE))
        val _ = assertEqualString "Tue Jan 02 03:04:05 2001" (Date.toString d)
      in () end

  (********************)

  local
    fun test arg expected =
        let
          val r = Date.scan List.getItem (String.explode arg)
          val _ = assertEqualDateCListOption expected r
        in
          ()
        end
  in
  fun scan0001 () =
      let
        val d = D.date (makeDate (2001, D.Jan, 2, 3, 4, 5, NONE))

        val scan_1 = test "Tue Jan 02 03:04:05 2001" (SOME(d, []))
        val scan_initws =
            test " \f\n\r\t\vTue Jan 02 03:04:05 2001" (SOME(d, []))
        val scan_trailer =
            test "Tue Jan 02 03:04:05 2001abc" (SOME(d, [#"a", #"b", #"c"]))
        val scan_invalid = test "Tue JanX 02 03:04:05 2001" NONE
      in () end
  end (* local *)

  (********************)

  fun fromString0001 () =
      let
        val d = D.date (makeDate (2001, D.Jan, 2, 3, 4, 5, NONE))

        val s1 = "Tue Jan 02 03:04:05 2001"
        val _ = assertEqualDateOption (SOME d) (D.fromString s1)

        val s_initws = " \f\n\r\t\vTue Jan 02 03:04:05 2001"
        val _ = assertEqualDateOption (SOME d) (D.fromString s_initws)

        val s_trailer = "Tue Jan 02 03:04:05 2001abc"
        val _ = assertEqualDateOption (SOME d) (D.fromString s_trailer)

        val s_invalid = "Tue JanX 02 03:04:05 2001"
        val _ = assertEqualDateOption NONE (D.fromString s_invalid)
      in () end

  (****************************************)

  fun suite () =
      T.labelTests
      [
        ("date_min", date_min),
        ("date_max", date_max),
        ("date_carry", date_carry),
        ("date_borrow", date_borrow),
        ("date_offset_0", date_offset_0),
        ("date_offset_1sec", date_offset_1sec),
        ("date_offset_1hour", date_offset_1hour),
        ("date_offset_over24h", date_offset_over24h),
        ("date_leap_001", date_leap_001),
        ("date_leap_002", date_leap_002),
        ("date_leap_003", date_leap_003),
        ("date_leap_004", date_leap_004),
        ("year0001", year0001),
        ("month0001", month0001),
        ("day0001", day0001),
        ("hour0001", hour0001),
        ("minute0001", minute0001),
        ("second0001", second0001),
        ("weekDay0001", weekDay0001),
        ("yearDay0001", yearDay0001),
        ("offset0001", offset0001),
        ("isDst0001", isDst0001),
        ("localOffset0001", localOffset0001),
        ("fromToTime_local", fromToTime_local),
        ("fromToTime_universal", fromToTime_universal),
        ("compare0001", compare0001),
        ("compare0002", compare0002),
        ("fmt0001", fmt0001),
        ("toString0001", toString0001),
        ("scan0001", scan0001),
        ("fromString0001", fromString0001)
      ]

  (************************************************************)

end