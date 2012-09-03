(**
 * Date structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Date.sml,v 1.3 2006/02/21 16:04:20 kiyoshiy Exp $
 *)
(* The runtime aborts if Date is constrained by DATE here. 
structure Date :> DATE =
*)
structure Date =
struct

  (***************************************************************************)

  structure LI = LargeInt

  (***************************************************************************)

  datatype weekday = Mon | Tue | Wed | Thu | Fri | Sat | Sun

  datatype month =
           Jan
         | Feb
         | Mar
         | Apr
         | May
         | Jun
         | Jul
         | Aug
         | Sep
         | Oct
         | Nov
         | Dec

  type date =
       {
         year : LI.int,
         month : LI.int, (* [0, 11] *)
         day : LI.int, (* [0, 30] The first day is 0. *)
         hour : LI.int, (* [0, 23] *)
         minute : LI.int, (* [0, 59] *)
         second : LI.int, (* [0, 60] (60 is for leap second) *)
         weekDay : LI.int, (* [0, 6] *)
         yearDay : LI.int, (* [0, 365] *)
         offset : Time.time option
       }

  (*
   * struct tm {
   *    int tm_sec;  // [0, 60] (60 is for leap second)
   *    int tm_min;  // [0, 59]
   *    int tm_hour; // [0, 23]
   *    int tm_mday; // [1, 31] Caution ! The first day is 1, not 0.
   *    int tm_mon;  // [0, 11]
   *    int tm_year; // elapsed years from 1900.
   *    int tm_wday; // [0, 6] Caution ! Sun = 0
   *    int tm_yday; // [0, 365]
   *    int tm_isdst; // ignored
   * };
   *)
  type tm = (int * int * int * int * int * int * int * int * int)

  (***************************************************************************)

  exception Date

  (***************************************************************************)

  infix rem quot
  val op quot = LI.quot
  val op rem = LI.rem

  fun weekDayToInt Mon = 0 : LI.int
    | weekDayToInt Tue = 1
    | weekDayToInt Wed = 2
    | weekDayToInt Thu = 3
    | weekDayToInt Fri = 4
    | weekDayToInt Sat = 5
    | weekDayToInt Sun = 6

  fun intToWeekDay 0 = Mon
    | intToWeekDay 1 = Tue
    | intToWeekDay 2 = Wed
    | intToWeekDay 3 = Thu
    | intToWeekDay 4 = Fri
    | intToWeekDay 5 = Sat
    | intToWeekDay 6 = Sun
    | intToWeekDay n = raise Fail ("bug:intToweekDay " ^ LI.toString n)

  fun monthToInt Jan = 0 : LI.int
    | monthToInt Feb = 1
    | monthToInt Mar = 2
    | monthToInt Apr = 3
    | monthToInt May = 4
    | monthToInt Jun = 5
    | monthToInt Jul = 6
    | monthToInt Aug = 7
    | monthToInt Sep = 8
    | monthToInt Oct = 9
    | monthToInt Nov = 10
    | monthToInt Dec = 11

  fun intToMonth 0 = Jan
    | intToMonth 1 = Feb
    | intToMonth 2 = Mar
    | intToMonth 3 = Apr
    | intToMonth 4 = May
    | intToMonth 5 = Jun
    | intToMonth 6 = Jul
    | intToMonth 7 = Aug
    | intToMonth 8 = Sep
    | intToMonth 9 = Oct
    | intToMonth 10 = Nov
    | intToMonth 11 = Dec
    | intToMonth n = raise Fail ("bug: intToMonth " ^ LI.toString n)

  fun tmToDate
          ((second, minute, hour, day, month, year, weekDay, yearDay, isDst)
           : tm) =
      {
        year = LI.fromInt year + 1900,
        month = LI.fromInt month,
        day = LI.fromInt day - 1,
        hour = LI.fromInt hour,
        minute = LI.fromInt minute,
        second = LI.fromInt second,
        weekDay = LI.fromInt weekDay,
        yearDay = LI.fromInt yearDay,
        offset = NONE
      }

  fun dateToTM (date : date) =
      (
        LI.toInt (#second date),
        LI.toInt (#minute date),
        LI.toInt (#hour date),
        LI.toInt (#day date) + 1,
        LI.toInt (#month date),
        LI.toInt (#year date) - 1900,
        (LI.toInt (#weekDay date) + 1) mod 7,
        LI.toInt (#yearDay date),
        (* isDst *) 0
      ) : tm

  (********************)

  fun year (date : date) = LI.toInt (#year date)
  fun month (date : date) = intToMonth (#month date)
  fun day (date : date) = LI.toInt (#day date) + 1 (* 0-base to 1-base *)
  fun hour (date : date) = LI.toInt (#hour date)
  fun minute (date : date) = LI.toInt (#minute date)
  fun second (date : date) = LI.toInt (#second date)
  fun weekDay (date : date) = intToWeekDay (#weekDay date)
  fun yearDay (date : date) = LI.toInt (#yearDay date)
  fun isDst (date : date) = NONE
  fun offset (date : date) = #offset date

  (********************)

  val secondsOfHour = 60 * 60 : LI.int
  val secondsOfDay = secondsOfHour * 24 : LI.int
  (* Time.zeroTime denotes 1970-01-01 00:00:00 (UTC) *)
  val epochYear = 1970 : LI.int

  fun isLeapYear (year : LI.int) =
      (0 = year mod 4) andalso (0 <> year mod 100 orelse 0 = year mod 400)

  local
    val normalTable : LI.int vector =
        Vector.fromList [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    val leapTable : LI.int vector =
        Vector.fromList [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  in
  fun daysOfMonth (year, month) =
      if month < 0 orelse 11 < month
      then raise Fail ("bug: month = " ^ LI.toString month)
      else
        if isLeapYear year
        then Vector.sub (leapTable, LI.toInt month)
        else Vector.sub (normalTable, LI.toInt month)
  fun daysOfYear year = if isLeapYear year then 366 else 365 : LI.int
  fun yearDayOfDate (year, month, day) =
      let
        val table = if isLeapYear year then leapTable else normalTable
        fun add 0 sum = sum + day
          | add month sum =
            add (month - 1) (Vector.sub (table, LI.toInt month - 1) + sum)
      in
        add month 0
      end
  fun weekDayOfDate (year, month, day) =
      (* calculate weekday by the Zeller's formulae. *)
      let
        val q = day + 1

        (*  Jan and Feb are interpreted as the 13th and 14th months of the
         * previous year.
         *  3 = March, 4 = April, 5 = May, ..., 14 = Feb
         *)
        val (year, m) =
            if month < 2 then (year - 1, month + 13) else (year, month + 1)

        val K = year mod 100

        val J = year div 100

        (* Use div since i div j = floor (i / j) *)
        (* h = 0 for Sat, 1 for Sun, 2 for Mon, ... *)
        val h =
            (q + (((m + 1) * 26) div 10) + K + (K div 4) + (J div 4) - 2 * J)
            mod 7

        (* d = 0 for Mon, 1 for Tue, 2 for Wed, ... *)
        val d = (h + 5) mod 7
      in
        d
      end
  end

  (********************)

  local
    (* For example,
     *   canonicalMonth (1999, 12) = (2000, 0)
     *   canonicalMonth (2000, ~1) = (1999, 11)
     *)
    fun canonicalMonth (year, month) = (year + month div 12, month mod 12)
    (*
     * adjusts the date so that day is in the range of days of the month.
     * For example, 
     *   canonicalDay (1999, 11, 31) = (2000, 0, 0) = 2000/1/1
     *   canonicalDay (2000, 0, ~1) = (1999, 11, 30) = 1999/12/31
     *   canonicalDay (2000, 1, 28) = (2000, 1, 28) = 2000/2/29
     *   canonicalDay (2000, 1, 29) = (2000, 2, 0) = 2000/3/1
     *)
    fun canonicalDay (year, month, day) =
        let val daysOfThisMonth = daysOfMonth (year, month)
        in
          if day < 0
          then
            (* the date is in the previous month or before. *)
            let
              val (newYear, newMonth) = canonicalMonth (year, month - 1)
              val newDay = day + daysOfMonth (newYear, newMonth)
            in canonicalDay (newYear, newMonth, newDay) end
              
          else if daysOfThisMonth <= day
          then
            (* the date is in the next month or later. *)
            let
              val (newYear, newMonth) = canonicalMonth (year, month + 1)
              val newDay = day - daysOfThisMonth
            in canonicalDay (newYear, newMonth, newDay) end
              
          else
            (* the date is in this month. *)
            (year, month, day)
        end
          
    (* adjusts an offset into the range of (~24h, 24h).
     * If offset = SOME(~32h), for example, (SOME(~8h), ~24h) is returned.
     *)
    fun canonicalOffset offset =
        let
          val (newOffset, carryHour) =
              case offset of
                NONE => (NONE, 0)
              | SOME(offsetTime) =>
                let
                  val offsetSeconds = Time.toSeconds offsetTime
                  val carryHour = (offsetSeconds quot secondsOfDay) * 24
                  val secondsOfCarryHour = carryHour * secondsOfHour
                  val newOffset =
                      Time.-(offsetTime, Time.fromSeconds secondsOfCarryHour)
                in
                  (SOME newOffset, carryHour)
                end
        in
          (newOffset, carryHour)
        end
  in
  fun internalDate {year, month, day, hour, minute, second, offset} =
      let
        (* converts the specified local date to a valid UTC date.
         * Fields of date are adjusted from bottom to upper:
         *   second, minute, hour, ...
         *)
        
        (* adjusts the second field to fit in the range [0, 59].
         * If second = ~32, for example,
         * newSecond = ~32 mod 60 = 28, carryMinute = ~32 div 60 = ~1.
         *)
        val (newSecond, carryMinute) = (second mod 60, second div 60)

        val minute = minute + carryMinute
        val (newMinute, carryHour) = (minute mod 60, minute div 60)

        val hour = hour + carryHour
        val (newOffset, carryHour) = canonicalOffset offset
        val hour = hour + carryHour
        val (newHour, carryDay) = (hour mod 24, hour div 24)

        val day = day + carryDay
        (* adjusts year and month before adjusts day. *)
        val (year, month) = canonicalMonth (year, month)
        (* Year, month and day fields are adjusted together. *)
        val (newYear, newMonth, newDay) = canonicalDay (year, month, day)

        val newYearDay = yearDayOfDate (newYear, newMonth, newDay)

        val newWeekDay = weekDayOfDate (newYear, newMonth, newDay)
      in
        {
          year = newYear,
          month = newMonth,
          day = newDay,
          hour = newHour,
          minute = newMinute,
          second = newSecond,
          weekDay = newWeekDay,
          yearDay = newYearDay,
          offset = newOffset
        } : date
      end
  end (* local *)

  fun date {year, month, day, hour, minute, second, offset} =
      internalDate
          {
            year = LI.fromInt year,
            month = monthToInt month,
            day = LI.fromInt(day - 1), (* changes day from 1-base to 0-base. *)
            hour = LI.fromInt hour,
            minute = LI.fromInt minute,
            second = LI.fromInt second,
            offset = offset
          }

  (********************)

  (* system API *)
(*
  val ascTime : tm -> string = SMLSharp.Runtime.Date_ascTime
  val gmTime : Int32.int -> tm = SMLSharp.Runtime.Date_gmTime
  val mkTime : tm -> Int32.int = SMLSharp.Runtime.Date_mkTime
*)
  val localTime : Int32.int -> tm = SMLSharp.Runtime.Date_localTime
  val strfTime : (string * tm) -> string = SMLSharp.Runtime.Date_strfTime
(*
  fun strfTime (string, tm : tm) = string
  fun localTime (int32 : Int32.int) = (0, 0, 0, 0, 0, 0, 0, 0, 0)
*)
  (********************)

  local
    (* caluculates the number of days between the first days of two years.
     *   daysBetweenYears (1997, 1999)
     *               = the number of days between 1997/1/1 and 1999/1/1
     *               = 365 + 365 = 730
     *   daysBetweenYears (1999, 2001) = 365 + 366 = 731
     *)
    fun daysBetweenYears (srcYear, dstYear) =
        if srcYear = dstYear
        then 0 : LI.int
        else if srcYear < dstYear
        then daysBetweenYears (srcYear, dstYear - 1) + daysOfYear (dstYear - 1)
        else daysBetweenYears (srcYear, dstYear + 1) - daysOfYear dstYear
    (* calculates the number of seconds between the Epoc and the argument.
     *)
    fun secondsFromEpoch (date : date) =
      let
        val diffDaysByYears = daysBetweenYears (epochYear, #year date)
        val yearDays = yearDayOfDate (#year date, #month date, #day date)
      in
        (diffDaysByYears + yearDays) * secondsOfDay
        + #hour date * 60 * 60
        + #minute date * 60
        + #second date
      end
  in
  fun localOffset () =
      let
        (* POSIX API gettimeofday and ftime return the timezone information.
         * But they are obsolete.
         * We use localTime to calculate the difference of UTC and local time.
         *)
        (* localTime converts UTC to the current local time zone.
         * The argument 0 denotes the Epoch in UTC.
         *)
        val tm = localTime 0
        val date = tmToDate tm
        val seconds = secondsFromEpoch date
      in
        Time.fromSeconds (~seconds)
      end

  fun toTime date =
      let
        (* converts the date to the number of seconds from Epoch. *)
        val seconds = secondsFromEpoch date
      in
        Time.+
        (
          Time.fromSeconds seconds,
          case #offset date of NONE => localOffset () | SOME offset => offset
        )
      end
  end

  fun fromTimeLocal time =
      let
        (* The 'time' argument is in UTC.
         * We have to convert it into the current local time zone.
         *)
        val time = Time.-(time, localOffset ())
        val date =
            internalDate
                {
                  year = epochYear,
                  month = 0,
                  day = 0,
                  hour = 0,
                  minute = 0,
                  second = Time.toSeconds time,
                  offset = NONE
                }
      in
        date
      end

  fun fromTimeUniv time =
      let
        val date =
            internalDate
                {
                  year = epochYear,
                  month = 0,
                  day = 0,
                  hour = 0,
                  minute = 0,
                  second = Time.toSeconds time,
                  offset = SOME (Time.zeroTime)
                }
      in
        date
      end

  (********************)

  local
    structure PC = ParserComb
    structure SS = Substring

    (* format characters which Date.fmt interprets.
     * This is a subset of characters which strftime primitive interprets.
     * For example, strftime primitive interprets '%D' while Date.fmt does not.
     *)
    val validSpecChars = "aAbBcdHIjmMpSUwWxXyYZ%"
    fun isValidSpecChar ch = CharVector.exists (fn c => ch = c) validSpecChars

    (* replaces '%c' to 'c' if 'c' is not included in the set of format
     * characters which Date.fmt interpret.
     * For example, " %A %D %% " is translated to " %A D %% " because 'D' is
     * not included in the format characters while 'A' and '%' are.
     *)
    fun scanChar reader stream = 
        PC.or
            (
              PC.or
                  (
                    PC.wrap
                        (
                          PC.seq (PC.char #"%", PC.eatChar isValidSpecChar),
                          fn (c1,c2) => [c1, c2]
                         ),
                    PC.wrap
                        (
                          PC.seq (PC.char #"%", PC.eatChar (fn _ => true)),
                          fn (_, c) => [c]
                         )
                  ),
                  PC.wrap (PC.eatChar (fn _ => true), fn c => [c])
            )
            reader stream
    fun scanFormat reader stream =
        PC.wrap
            (PC.zeroOrMore scanChar, fn css => String.implode(List.concat css))
        reader stream
  in
  fun fmt format (date : date) =
      let
        val format = case StringCvt.scanString scanFormat format
                      of NONE => ""
                       | SOME format => format
        val tm = dateToTM date
      in
        strfTime (format, tm)
      end
  end (* local *)

  val toString = fmt "%a %b %d %H:%M:%S %Y"

  (********************)

  local
    structure PC = ParserComb
    fun scanWeekDay reader stream =
        PC.or'
            [
              PC.seqWith #2 (PC.string "Mon", PC.result Mon),
              PC.seqWith #2 (PC.string "Tue", PC.result Tue),
              PC.seqWith #2 (PC.string "Wed", PC.result Wed),
              PC.seqWith #2 (PC.string "Thu", PC.result Thu),
              PC.seqWith #2 (PC.string "Fri", PC.result Fri),
              PC.seqWith #2 (PC.string "Sat", PC.result Sat),
              PC.seqWith #2 (PC.string "Sun", PC.result Sun)
            ]
            reader stream

    fun scanMonth reader stream =
        PC.or'
            [
              PC.seqWith #2 (PC.string "Jan", PC.result Jan),
              PC.seqWith #2 (PC.string "Feb", PC.result Feb),
              PC.seqWith #2 (PC.string "Mar", PC.result Mar),
              PC.seqWith #2 (PC.string "Apr", PC.result Apr),
              PC.seqWith #2 (PC.string "May", PC.result May),
              PC.seqWith #2 (PC.string "Jun", PC.result Jun),
              PC.seqWith #2 (PC.string "Jul", PC.result Jul),
              PC.seqWith #2 (PC.string "Aug", PC.result Aug),
              PC.seqWith #2 (PC.string "Sep", PC.result Sep),
              PC.seqWith #2 (PC.string "Oct", PC.result Oct),
              PC.seqWith #2 (PC.string "Nov", PC.result Nov),
              PC.seqWith #2 (PC.string "Dec", PC.result Dec)
            ]
            reader stream

    fun numOfDigit ch = LI.fromInt (Char.ord ch - Char.ord #"0")
    (* scan "d" (= a digit). *)
    fun scan1Digit reader stream =
        PC.wrap (PC.eatChar Char.isDigit, numOfDigit) reader stream
    (* scan "dd" *)
    fun scan2Digits reader stream =
        PC.wrap
            (PC.seq (scan1Digit, scan1Digit), fn (n1, n2) => n1 * 10 + n2)
            reader stream
    (* scan "dddd" *)
    fun scan4Digits reader stream =
        PC.wrap
            (PC.seq (scan2Digits, scan2Digits), fn (n1, n2) => n1 * 100 + n2)
            reader stream

    fun field scan separator scanTail reader stream =
        PC.seq
            (PC.seqWith #1 (scan, PC.char separator), scanTail) reader stream

    (* scan "dd:dd:dd" *)
    fun scanTime reader stream =
        PC.wrap
            (
              field scan2Digits #":" (field scan2Digits #":" scan2Digits),
              fn (hour, (minute, second)) => (hour, minute, second)
            )
            reader stream
    (* scan "WKD MON dd dd:dd:dd dddd" *)
    fun scanDate reader stream =
        PC.wrap
            (
              field scanWeekDay #" "
                    (field scanMonth #" " 
                           (field scan2Digits #" "
                                  (field scanTime #" " scan4Digits))),
              fn (weekDay, (month, (day, ((hour, minute, second), year)))) =>
                 {
                   year = year,
                   month = monthToInt month,
                   day = day - 1, (* change 1-base to 0-base *)
                   hour = hour,
                   minute = minute,
                   second = second,
                   weekDay = weekDayToInt weekDay,
                   yearDay = yearDayOfDate (year, monthToInt month, day),
                   offset = NONE
                 } : date
            )
            reader stream
  in

  fun scan reader stream = scanDate reader (StringCvt.skipWS reader stream)

  end (* local *)

  val fromString = StringCvt.scanString scan

  (********************)

  local
    (* compares fields sequentially until a field of which values are not
     * EQUAL is found. *)
    fun comp [] _ = EQUAL
      | comp (selector :: selectors) (left, right) = 
        case LI.compare (selector left, selector right)
         of General.LESS => LESS
          | General.GREATER => GREATER
          | General.EQUAL => comp selectors (left, right)
  in
  fun compare (left : date, right : date) =
      comp [#year, #month, #day, #hour, #minute, #second] (left, right)
  end

  (***************************************************************************)

end;