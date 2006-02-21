(**
 * Copyright (c) 2006, Tohoku University.
 *
 * implementation of primitives on date values.
 * @author YAMATODANI Kiyoshi
 * @version $Id: DatePrimitives.sml,v 1.2 2006/02/18 04:59:39 ohori Exp $
 *)
structure DatePrimitives : PRIMITIVE_IMPLEMENTATIONS =
struct

  (***************************************************************************)

  open RuntimeTypes
  open BasicTypes
  structure RE = RuntimeErrors
  structure SLD = SourceLanguageDatatypes
  structure H = Heap

  (***************************************************************************)

  fun intToWeekDay 0 = Date.Sun
    | intToWeekDay 1 = Date.Mon
    | intToWeekDay 2 = Date.Tue
    | intToWeekDay 3 = Date.Wed
    | intToWeekDay 4 = Date.Thu
    | intToWeekDay 5 = Date.Fri
    | intToWeekDay 6 = Date.Sat

  fun weekDayToInt Date.Sun = 0
    | weekDayToInt Date.Mon = 1
    | weekDayToInt Date.Tue = 2
    | weekDayToInt Date.Wed = 3
    | weekDayToInt Date.Thu = 4
    | weekDayToInt Date.Fri = 5
    | weekDayToInt Date.Sat = 6

  fun intToMonth 0 = Date.Jan
    | intToMonth 1 = Date.Feb
    | intToMonth 2 = Date.Mar
    | intToMonth 3 = Date.Apr
    | intToMonth 4 = Date.May
    | intToMonth 5 = Date.Jun
    | intToMonth 6 = Date.Jul
    | intToMonth 7 = Date.Aug
    | intToMonth 8 = Date.Sep
    | intToMonth 9 = Date.Oct
    | intToMonth 10 = Date.Nov
    | intToMonth 11 = Date.Dec

  fun monthToInt Date.Jan = 0
    | monthToInt Date.Feb = 1
    | monthToInt Date.Mar = 2
    | monthToInt Date.Apr = 3
    | monthToInt Date.May = 4
    | monthToInt Date.Jun = 5
    | monthToInt Date.Jul = 6
    | monthToInt Date.Aug = 7
    | monthToInt Date.Sep = 8
    | monthToInt Date.Oct = 9
    | monthToInt Date.Nov = 10
    | monthToInt Date.Dec = 11

  fun TMToDate [sec, min, hour, mday, mon, year, wday, yday, isdst] =
      let
        fun toInt cell = SInt32ToInt(intOf "TMToDa" cell)
      in
        Date.date
            {
              year = toInt year,
              month = intToMonth(toInt mon),
              day = toInt mday,
              hour = toInt hour,
              minute = toInt min,
              second = toInt sec,
              offset = NONE
            }
      end
    | TMToDate _ = 
      raise RE.UnexpectedPrimitiveArguments "TMToDate"

  fun dateDstToInt date =
      case Date.isDst date of
        NONE => ~1
      | SOME false => 0
      | SOME true => 1

  fun intToDst num =
      if num < 0 then NONE else if num = 0 then SOME false else SOME true

  fun dateToTM date =
      map
          (fn f => (Int o IntToSInt32 o f) date)
          [
            Date.second,
            Date.minute,
            Date.hour,
            Date.day,
            monthToInt o Date.month,
            Date.year,
            weekDayToInt o Date.weekDay,
            Date.yearDay,
            dateDstToInt
          ]

  (* tm -> string *)
  fun Date_ascTime
          VM
          heap
          (args
           as [Int _, Int _, Int _, Int _, Int _, Int _, Int _, Int _, Int _])
      =
      let
        val date = TMToDate args
        val string = Date.toString date
      in
        [SLD.stringToValue heap string]
      end
    | Date_ascTime _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "Date_ascTime"

  (* int -> tm *)
  fun Date_localTime VM heap [Int seconds] =
      let
        val localDate = Date.fromTimeLocal(Time.fromSeconds seconds)
        val localTM = dateToTM localDate
      in
        [SLD.tupleElementsToValue heap 0w0 localTM]
      end
    | Date_localTime _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "Date_localTime"

  (* int -> tm *)
  fun Date_gmTime VM heap [Int seconds] =
      let
        val univDate = Date.fromTimeUniv(Time.fromSeconds seconds)
        val univTM = dateToTM univDate
      in
        [SLD.tupleElementsToValue heap 0w0 univTM]
      end
    | Date_gmTime _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "Date_gmTime"

  (* tm -> int *)
  fun Date_mkTime
          VM
          heap
          (args
           as [Int _, Int _, Int _, Int _, Int _, Int _, Int _, Int _, Int _])
      =
      let
        val date = TMToDate args
        val time = Date.toTime date
        val seconds = Time.toSeconds time
      in
        [Int seconds]
      end
    | Date_mkTime _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "Date_mkTime"

  (* (string * tm) -> string *)
  fun Date_strfTime
          VM
          heap
          [formatStringAddress as Pointer _, TMAddress as Pointer _] =
      let
        val formatString = SLD.valueToString heap formatStringAddress
        val TMElements = SLD.valueToTupleElements heap TMAddress
        val _ =
            if
              (List.exists (fn Int _ => false | _ => true) TMElements)
              orelse 9 <> List.length TMElements
            then raise RE.UnexpectedPrimitiveArguments "Date_mkTime"
            else ()
        val date = TMToDate TMElements
        val string = Date.fmt formatString date
      in
        [SLD.stringToValue heap string]
      end
    | Date_strfTime _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "Date_mkTime"

  val primitives =
      [
        {name = "Date_ascTime", function = Date_ascTime},
        {name = "Date_localTime", function = Date_localTime},
        {name = "Date_gmTime", function = Date_gmTime},
        {name = "Date_mkTime", function = Date_mkTime},
        {name = "Date_strfTime", function = Date_strfTime}
      ]

  (***************************************************************************)

end;
