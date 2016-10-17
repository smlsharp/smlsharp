structure SMLSharp_SQL_TimeStamp :> 
sig
  type timestamp
  val now : unit -> timestamp
  val toString : timestamp -> string
  val fromString : string -> timestamp
  val defaultTimestamp : timestamp
  val compare : timestamp * timestamp -> order
end
=
struct
  exception IlleagalTimeStampFormat
  type timestamp = Time.time
  val compare = Time.compare
  fun now () = Time.now()
  fun toString timestamp = 
      let
        fun lastN (S,n) =
            let
              val pos = Substring.size (Substring.full S) - n
              val (_,lastN) = Substring.splitAt (Substring.full S, pos)
            in
              Substring.string lastN
            end
        val microseconds = Time.toMicroseconds timestamp
        val microOffset = lastN(IntInf.toString microseconds, 6)
        val dateRep = 
            Date.fmt "%Y-%m-%d %H:%M:%S" (Date.fromTimeLocal timestamp)
        val dateRepFull = dateRep ^ "." ^ microOffset
        val offsetHour = 
            Date.hour
              (Date.fromTimeUniv 
                 (Time.- (Time.zeroTime, Date.localOffset ())))
        val offsetString = 
            if offsetHour = 0 then ""
            else if offsetHour > 0 then 
              " +" ^ (Int.toString offsetHour) ^ ":00"
            else " -" ^ (Int.toString (offsetHour * ~1))  ^ ":00"
      in
        dateRep 
        ^ "." 
        ^ microOffset
        ^ offsetString
      end

  fun fromString string = 
  (* string format: 2016-08-14 10:44:45.753904 +9:00 *)
      let
        fun puts s = print (s ^ "\n")
        fun check ss = case Int.fromString ss of 
                         SOME i => i 
                       | NONE => raise IlleagalTimeStampFormat
        fun checkInf ss = case IntInf.fromString ss of 
                            SOME i => i 
                          | NONE => raise IlleagalTimeStampFormat
        val substring = Substring.full string
        val (YYMMDD, hhmmssMicrosec, offset) = 
            case Substring.fields (fn c => c = #" ") substring of
              [x,y,z] => (x,y, SOME z)
            | [x,y] => (x,y, NONE)
            | _ => raise  IlleagalTimeStampFormat
        val (YY, MM, DD) = 
            case map 
                   Substring.string
                   (Substring.fields (fn c => c = #"-") YYMMDD)
             of
              [x,y,z] => (x,y,z)
            | _ => raise  IlleagalTimeStampFormat
        val (hhmmss, Microsec) = 
            case Substring.fields (fn c => c = #".") hhmmssMicrosec of
              [x,y] => (x,y)
            | _ => raise  IlleagalTimeStampFormat
        val microsec = Substring.string Microsec
        val (hh, mm, ss) = 
            case map Substring.string
                     (Substring.fields (fn c => c = #":") hhmmss)
             of
              [x,y,z] => (x,y,z) 
            | _ => raise  IlleagalTimeStampFormat
        val year = check YY
        val monthNum = check MM
        val month = 
            case monthNum of
               1 => Date.Jan 
             | 2 => Date.Feb 
             | 3 => Date.Mar 
             | 4 => Date.Apr 
             | 5 => Date.May 
             | 6 => Date.Jun 
             | 7 => Date.Jul 
             | 8 => Date.Aug 
             | 9 => Date.Sep 
             | 10 => Date.Oct 
             | 11 => Date.Nov 
             | 12 => Date.Dec
             | _ => raise IlleagalTimeStampFormat
        val day = check DD
        val hour = check hh
        val minute = check mm
        val second = check ss
        val microsec = checkInf microsec
        val dateRecord =
            {day = day, 
             hour = hour, 
             minute = minute, 
             month = month,
             offset =  NONE,
             second = second,
             year = year}
        val date = Date.date dateRecord
        val microSecTime = Time.fromMicroseconds microsec
        val timeInSecond = Date.toTime date
        val timeInMicrosecond = Time.+(timeInSecond, microSecTime)
        val microSeconds = Time.toMicroseconds timeInMicrosecond
      in
        timeInMicrosecond
      end
  val defaultTimestamp = Time.zeroTime
end
(*
  val defaultTimestamp : timestamp
*)
