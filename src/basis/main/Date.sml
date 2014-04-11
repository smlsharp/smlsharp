(**
 * Date structure.
 * @author UENO Katsuhiro
 * @copyright 2013, Tohoku University.
 *)

infix 7 * / div mod
infix 6 + -
infix 4 = <> > >= < <=
val op * = IntInf.*
val op div = IntInf.div
val op + = IntInf.+
val op - = IntInf.-
val op < = IntInf.<
val op >= = IntInf.>=
val op > = SMLSharp_Builtin.Int.gt
structure Int = SMLSharp_Builtin.Int
(*
structure Int = struct
  open Int
  val rem_unsafe = rem
  val quot_unsafe = quot
  val mul_unsafe = op *
  val add_unsafe = op +
  val sub_unsafe = op -
end
*)

structure Date =
struct

  type intinf = IntInf.int

  datatype weekday = Mon | Tue | Wed | Thu | Fri | Sat | Sun
  datatype month = Jan | Feb | Mar | Apr | May | Jun
                   | Jul | Aug | Sep | Oct | Nov | Dec
  exception Date

  type date =
      {
        jd : intinf,
        seconds : int,
        year : int,
        month : month,
        day : int,
        hour : int,
        minute : int,
        second : int,
        offset : Time.time option
      }

  val EPOCH_JULIAN = 1721118 : intinf            (* 0-03-01 Julian *)
  val EPOCH_GREGORIAN = 1721120 : intinf         (* 0-03-01 Gregorian *)
  val START_GREGORIAN_ITALY = 2299161 : intinf   (* 1582-10-05 Julian *)
  val START_GREGORIAN_ENGLAND = 2361222 : intinf (* 1752-09-03 Julian *)
  val START_GREGORIAN = START_GREGORIAN_ENGLAND
  val EPOCH_UNIX = 2440588 : intinf              (* 1970-01-01 Gregorian *)
  val year1 = 365 : intinf
  val years4 = 1461 : intinf      (* = year1 * 4 + 1 *)
  val years100 = 36524 : intinf   (* = years4 * 25 - 1 *)
  val years400 = 146097 : intinf  (* = years100 * 4 + 1 *)

  fun firstDayNumberInYear month =
      case month of
        Mar => 0
      | Apr => 31
      | May => 61
      | Jun => 92
      | Jul => 122
      | Aug => 153
      | Sep => 184
      | Oct => 214
      | Nov => 245
      | Dec => 275
      | Jan => 306
      | Feb => 337

  fun dayNumberInYearToMonth dn =
      if dn < 184
      then if dn < 92
           then if dn < 31 then Mar
                else if dn < 61 then Apr
                else May
           else if dn < 122 then Jun
           else if dn < 153 then Jul
           else Aug
      else if dn < 275
      then if dn < 214 then Sep
           else if dn < 245 then Oct
           else Nov
      else if dn < 306 then Dec
      else if dn < 337 then Jan
      else Feb

  fun toOrdinalDate (yy : IntInf.int, mm : month, dd : IntInf.int) =
      (case mm of Jan => yy - 1 | Feb => yy - 1 | _ => yy,
       IntInf.fromInt (Int.sub_unsafe (firstDayNumberInYear mm, 1)) + dd)

  fun julianCalendar (yy : IntInf.int, nd : IntInf.int) =
      365 * yy + yy div 4 + nd + EPOCH_JULIAN

  fun gregorianCalendar (yy : IntInf.int, nd : IntInf.int) =
      365 * yy + yy div 4 - yy div 100 + yy div 400 + nd + EPOCH_GREGORIAN

  fun julianDay date =
      let
        val od = toOrdinalDate date
        val jd = julianCalendar od
      in
        if jd < START_GREGORIAN then jd else gregorianCalendar od
      end

  fun julianOrdinalDate jd =
      let
        val jd = jd - EPOCH_JULIAN
        val (y1, n1) = IntInf.divMod (jd, years4)
        val (y2, n2) = if n1 = years4 - 1
                       then (3, year1)
                       else IntInf.divMod (n1, year1)
      in
        (y1 * 4 + y2, n2)
      end

  fun gregorianOrdinalDate jd =
      let
        val jd = jd - EPOCH_GREGORIAN
        val (y1, n1) = IntInf.divMod (jd, years400)
        val (y2, n2) = if n1 = years400 - 1
                       then (3, years100)
                       else IntInf.divMod (n1, years100)
        val (y3, n3) = IntInf.divMod (n2, years4)
        val (y4, n4) = if n3 = years4 - 1
                       then (3, year1)
                       else IntInf.divMod (n3, year1)
      in
        (y1 * 400 + y2 * 100 + y3 * 4 + y4, n4)
      end

  fun ordinalDate jd =
      if jd >= START_GREGORIAN
      then gregorianOrdinalDate jd
      else julianOrdinalDate jd

  fun toDate jd =
      let
        val (yy, nd) = ordinalDate jd
        val mm = dayNumberInYearToMonth nd
        val yy = case mm of Jan => yy + 1 | Feb => yy + 1 | _ => yy
      in
        (yy, mm,
         nd - IntInf.fromInt (Int.sub_unsafe (firstDayNumberInYear mm, 1)))
      end

  fun toHMS seconds =
      let
        val s = Int.rem_unsafe (seconds, 60)
        val n = Int.quot_unsafe (seconds, 60)
        val m = Int.rem_unsafe (n, 60)
        val h = Int.quot_unsafe (n, 60)
      in
        (h, m, s)
      end

  fun normalizeTimeZone offset =
      case offset of
        NONE => (0, NONE)
      | SOME t =>
        if Time.< (Time.fromSeconds ~86400, t)
           andalso Time.< (t, Time.fromSeconds 86400)
        then (0, SOME t)
        else let val q = IntInf.quot (Time.toSeconds t, 86400)
                 val t = Time.- (t, Time.fromSeconds (q * 86400))
             in (q, SOME t)
             end

  fun date' (year, month, day, hour, minute, second, offset) =
      let
        val d1 = julianDay (year, month, day)
        val (d2, offset) = normalizeTimeZone offset
        val seconds = second + minute * 60 + hour * 3600
        val (d3, seconds) = IntInf.divMod (seconds, 86400)
        val jd = d1 + d2 + d3
        val seconds = IntInf.toInt seconds
        val (year, month, day) = toDate jd
        val (hour, minute, second) = toHMS seconds
      in
        {jd = jd,
         seconds = seconds,
         year = IntInf.toInt year,
         month = month,
         day = IntInf.toInt day,
         hour = hour,
         minute = minute,
         second = second,
         offset = offset} : date
        handle Overflow => raise Date
      end

  fun date {year, month, day, hour, minute, second, offset} =
      date' (IntInf.fromInt year,
             month,
             IntInf.fromInt day,
             IntInf.fromInt hour,
             IntInf.fromInt minute,
             IntInf.fromInt second,
             offset)

  fun year ({year, ...}:date) = year
  fun month ({month, ...}:date) = month
  fun day ({day, ...}:date) = day
  fun hour ({hour, ...}:date) = hour
  fun minute ({minute, ...}:date) = minute
  fun second ({second, ...}:date) = second
  fun offset ({offset, ...}:date) = offset
  fun isDst (_:date) = NONE : bool option

  fun toTime ({jd, hour, minute, second, ...}:date) =
      Time.fromSeconds
        ((jd - EPOCH_UNIX) * 86400
         + IntInf.fromInt (let val op * = Int.mul_unsafe
                               val op + = Int.add_unsafe
                           in hour * 3600 + minute * 60 + second
                           end))

  (* ISO 8601 says that 2000-01-01 (Julian day number 2451545) is saturday *)
  fun weekDay ({jd, ...}:date) =
      case IntInf.toInt (IntInf.mod (jd, 7)) of
        0 => Mon
      | 1 => Tue
      | 2 => Wed
      | 3 => Thu
      | 4 => Fri
      | 5 => Sat
      | 6 => Sun
      | _ => raise Fail "weekDay"

  fun yearDay ({jd, year, month, day, ...}:date) =
      IntInf.toInt (jd - julianDay (IntInf.fromInt year, Jan, 1))

  fun compare ({jd=jd1, seconds=s1, ...}:date,
               {jd=jd2, seconds=s2, ...}:date) =
      case IntInf.compare (jd1, jd2) of
        General.EQUAL =>
        if s1 = s2
        then General.EQUAL
        else if s1 > s2 then General.GREATER else General.LESS
      | x => x

  val prim_Date_localOffset =
      _import "prim_Date_localOffset"
      : __attribute__((no_callback))
        int ref -> int

  fun localOffset' () =
      let
        val ret = ref 0
        val err = prim_Date_localOffset ret
        val _ = if 0 > err then raise SMLSharp_Runtime.OS_SysErr () else ()
      in
        IntInf.fromInt (!ret)
      end

  fun localOffset () =
      Time.fromSeconds (localOffset' ())

  fun fromTimeUniv t =
      date' (1970, Jan, 1, 0, 0, Time.toSeconds t, SOME Time.zeroTime)
  fun fromTimeLocal t =
      date' (1970, Jan, 1, 0, 0, Time.toSeconds t + localOffset' (), NONE)

  val prim_time_to_string =
      _import "prim_time_to_string"
      : __attribute__((no_callback))
                     (int, CharArray.array, string) -> int
  val prim_string_to_time =
      _import "prim_string_to_time"
      : __attribute__((no_callback))
                     (string, string) -> int
  val prim_set_lctime =
      _import "prim_set_lctime"
      : __attribute__((no_callback))
         string -> char ptr

  fun fmt format date =
      let
        val time = toTime date
        val timeT = IntInf.toInt (Time.toSeconds time)
        val cstring = CharArray.array(256, #"\000")
        val locale = OS.Process.getEnv "LC_TIME"
        val _ = case locale of
                  SOME locale => (prim_set_lctime locale; ())
                | NONE => ()
        val res = prim_time_to_string(timeT, cstring, format)
        val _ = if res = 0 then raise Date else ()
        val slice = CharArraySlice.slice (cstring, 0, SOME res)
      in
        CharArraySlice.vector slice
      end

  fun toString date = fmt "%c" date

  fun fromStringWithFormat fmt string =
      let
        val timeT = prim_string_to_time(string, fmt)
      in
        if timeT = ~1 then NONE
        else SOME (fromTimeUniv(Time.fromSeconds (IntInf.fromInt timeT)))
      end

  fun fromString string = fromStringWithFormat "%c" string

  fun scan _ = raise Fail "FIXME: Date.scan: not implemented"

(*
  fun toString _ = raise Fail "FIXME: Date.toString: not implemented"
  fun fmt _ = raise Fail "FIXME: Date.fmt: not implemented"
  val fmt : string -> date -> string
  val toString : date -> string
  val scan : (char, 'a) StringCvt.reader -> (date, 'a) StringCvt.reader
  val fromString : string -> date option
*)

end
