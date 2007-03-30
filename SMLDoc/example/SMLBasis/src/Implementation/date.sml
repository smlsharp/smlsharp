(* date.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 *)

local
    structure Int = IntImp
    structure Int32 = Int32Imp
    structure Time = TimeImp
in
structure Date : DATE =
  struct


	(* the run-time system indexes the year off this *)
	val baseYear = 1900
	    
	exception Date

	datatype weekday = Mon | Tue | Wed | Thu | Fri | Sat | Sun

	datatype month
	    = Jan | Feb | Mar | Apr | May | Jun
	  | Jul | Aug | Sep | Oct | Nov | Dec

	datatype date = DATE of {
				 year : int,
				 month : month,
				 day : int,
				 hour : int,
				 minute : int,
				 second : int,
				 offset : Time.time option,
				 wday : weekday,
				 yday : int,
				 isDst : bool option
				 }

	(* tables for mapping integers to days/months *)
	val dayTbl = #[Sun, Mon, Tue, Wed, Thu, Fri, Sat]
	val monthTbl = #[Jan, Feb, Mar, Apr, May, Jun, Jul, 
			 Aug, Sep, Oct, Nov, Dec]

	fun dayToInt Sun = 0
	  | dayToInt Mon = 1
	  | dayToInt Tue = 2
	  | dayToInt Wed = 3
	  | dayToInt Thu = 4
	  | dayToInt Fri = 5
	  | dayToInt Sat = 6

	(* careful about this: the month numbers are 0-11 *)
	fun monthToInt Jan = 0
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
	  | monthToInt Doc = 11

	(* the tuple type used to communicate with C; this 9-tuple has the
	 * fields:
	 *   tm_sec, tm_min, tm_hour, tm_mday, tm_mon, tm_year,
	 *   tm_wday, tm_yday,
	 *   tm_isdst.
	 *)
	type tm = (int * int * int * int * int * int * int * int * int)

	(* wrap a C function call with a handler that maps SysErr
	 * exception into Date exceptions.
	 *)
	fun wrap f x = (f x) handle _ => raise Date

	(* note: mkTime assumes the tm structure passed to it reflects
	 * the local time zone
	 *)
	val ascTime : tm -> string
	    = wrap (CInterface.c_function "SMLNJ-Date" "ascTime")
	val localTime' : Int32.int -> tm
	    = wrap (CInterface.c_function "SMLNJ-Date" "localTime")
	val gmTime' : Int32.int -> tm
	    = wrap (CInterface.c_function "SMLNJ-Date" "gmTime")
	val mkTime' : tm -> Int32.int
	    = wrap (CInterface.c_function "SMLNJ-Date" "mkTime")
	val strfTime : (string * tm) -> string
	    = wrap (CInterface.c_function "SMLNJ-Date" "strfTime")

	val localTime = localTime' o Int32.fromLarge o Time.toSeconds
	val gmTime = gmTime' o Int32.fromLarge o Time.toSeconds
	val mkTime = Time.fromSeconds o Int32.toLarge o mkTime'

	fun year (DATE{year, ...}) = year
	fun month (DATE{month, ...}) = month
	fun day (DATE{day, ...}) = day
	fun hour (DATE{hour, ...}) = hour
	fun minute (DATE{minute, ...}) = minute
	fun second (DATE{second, ...}) = second
	fun weekDay (DATE{wday, ...}) = wday
	fun yearDay (DATE{yday, ...}) = yday
	fun isDst (DATE{isDst, ...}) = isDst
	fun offset (DATE{offset,...}) = offset

	(* takes two tm's and returns the second tm with 
	 * its dst flag set to the first one's.
	 * Used to compute local offsets 
	 *)
	fun withDst dst (tm2 : tm) : tm=
	    (#1 tm2, #2 tm2, #3 tm2, #4 tm2, #5 tm2, #6 tm2, #7 tm2, #8 tm2,
	     dst)

	fun dstOf (tm : tm) = #9 tm

	fun localOffset' () = let
	    val t = Int32.fromLarge (Time.toSeconds (Time.now ()))
	    val t_as_utc_tm = gmTime' t
	    val t_as_loc_tm = localTime' t
	    val loc_dst = dstOf t_as_loc_tm
	    val t_as_utc_tm' = withDst loc_dst t_as_utc_tm
	    val t' = mkTime' t_as_utc_tm'
	    val time = Time.fromSeconds o Int32.toLarge
	in
	    (Time.- (time t', time t), loc_dst)
	end

	val localOffset = #1 o localOffset'

	(* 
	 * This code is taken from Reingold's paper
	 *)
	local 
	    val quot = Int.quot
	    val not = Bool.not
	    fun sum (f,k,p) = 
		let fun loop (f,i,p,acc) = if (not(p(i))) then acc
					   else loop(f,i+1,p,acc+f(i))
		in
		    loop (f,k,p,0)
		end
	    fun lastDayOfGregorianMonth (month,year) =
		if ((month=1) andalso 
		    (Int.mod (year,4) = 0) andalso 
		    not (Int.mod (year,400) = 100) andalso
		    not (Int.mod (year,400) = 200) andalso
		    not (Int.mod (year,400) = 300))
		    then 29
		else List.nth ([31,28,31,30,31,30,31,31,30,31,30,31],month)
	in
	    fun toAbsolute (month, day, year) =
		day  
		+ sum (fn (m) => lastDayOfGregorianMonth(m,year),0,
		       fn (m) => (m<month)) 
		+ 365 * (year -1)
		+ quot (year-1,4)
		- quot (year-1,100)
		+ quot (year-1,400)
	    fun fromAbsolute (abs) =
		let val approx = quot (abs,366)
		    val year = (approx + sum(fn(_)=>1, approx, 
					     fn(y)=> (abs >= toAbsolute(0,1,y+1))))
		    val month = (sum (fn(_)=>1, 0,
				      fn(m)=> (abs > toAbsolute(m,lastDayOfGregorianMonth(m,year),year))))
		    val day = (abs - toAbsolute(month,1,year) + 1)
		in
		    (month, day, year)
		end
	    fun wday (month,day,year) =
		let val abs = toAbsolute (month,day,year)
		in
		    InlineT.PolyVector.sub (dayTbl, Int.mod(abs,7))
		end
	    fun yday (month, day, year) = 
		let val abs = toAbsolute (month, day, year)
		    val daysPrior = 
			365 * (year -1)
			+ quot (year-1,4)
			- quot (year-1,100)
			+ quot (year-1,400)
		in 
		    abs - daysPrior - 1    (* to conform to ISO standard *)
		end
	end

	(*
	 * this function should also canonicalize the time (hours, etc...)
	 *)
	fun canonicalizeDate (DATE d) = 
	    let val args = (monthToInt(#month d), #day d, #year d)
		val (monthC,dayC,yearC) = fromAbsolute (toAbsolute (args))
		val yday = yday (args)
		val wday = wday (args)
	    in
		DATE {year = yearC,
		      month = InlineT.PolyVector.sub (monthTbl,monthC),
		      day = dayC,
		      hour = #hour d,
		      minute = #minute d,
		      second = #second d,
		      offset = #offset d,
		      isDst = NONE,
		      yday = yday,
		      wday = wday}
	    end

	fun toTM (DATE d) = (
			     #second d,			(* tm_sec *)
			     #minute d,			(* tm_min *)
			     #hour d,			(* tm_hour *)
			     #day d,			(* tm_mday *)
			     monthToInt(#month d),	(* tm_mon *)
			     #year d - baseYear,		(* tm_year *)
			     dayToInt(#wday d),		(* tm_wday *)
			     0,				(* tm_yday *)
			     case (#isDst d)		(* tm_isdst *)
				 of NONE => ~1
			       | (SOME false) => 0
			       | (SOME true) => 1
				     (* end case *)
				     )

	fun fromTM (tm_sec, tm_min, tm_hour, tm_mday, tm_mon,
		    tm_year, tm_wday, tm_yday, tm_isdst) offset =
	    DATE { year = baseYear + tm_year,
		   month = InlineT.PolyVector.sub (monthTbl, tm_mon),
		   day = tm_mday,
		   hour = tm_hour,
		   minute = tm_min,
		   second = tm_sec,
		   wday = InlineT.PolyVector.sub (dayTbl, tm_wday),
		   yday = tm_yday,
		   isDst = if (tm_isdst < 0) then NONE
			   else SOME(tm_isdst <> 0),
		   offset = offset }


	fun fromTimeLocal t = fromTM (localTime t) NONE

	fun fromTimeUniv t = fromTM (gmTime t) (SOME Time.zeroTime)

	fun fromTimeOffset (t, offset) =
	    fromTM (gmTime (Time.- (t, offset))) (SOME offset)

	val day_seconds = IntInfImp.fromInt (24 * 60 * 60)
	val hday_seconds = IntInfImp.fromInt (12 * 60 * 60)

	fun canonicalOffset off = let
	    val offs = Time.toSeconds off
	    val offs' = offs mod day_seconds
	    val offs'' = if offs' > hday_seconds then offs' - day_seconds
			 else offs'
	in
	    Time.fromSeconds offs''
	end

	fun toTime d = let
	    val tm = toTM d
	in
	    case offset d of
		NONE => mkTime tm
	      | SOME tm_utc_off => let
		    val tm_utc_off = canonicalOffset tm_utc_off
		    val (loc_utc_off, loc_dst) = localOffset' ()
		    (* time west of here *)
		    val tm_loc_off = Time.- (tm_utc_off, loc_utc_off)
		in
		    (* pretend tm refers to local time, then subtract
		     * difference between dest. and local time *)
		    Time.- (mkTime (withDst loc_dst tm), tm_loc_off)
		end
	end

	fun date { year, month, day, hour, minute, second, offset } = let
	    val d = DATE { second = second,
			   minute = minute,
			   hour = hour,
			   year = year,
			   month = month, 
			   day = day,
			   offset = offset,
			   isDst = NONE,
			   yday = 0,
			   wday = Mon }
	    val canonicalDate = canonicalizeDate d
	    fun internalDate () =
		case offset of
		    NONE => fromTimeLocal (toTime canonicalDate)
		  | SOME off => fromTimeOffset (toTime canonicalDate, off)
	    in
		internalDate () handle Date => d
	    end

	fun toString d = ascTime (toTM d)
	fun fmt fmtStr d = strfTime (fmtStr, toTM d)

	fun scan getc s = let

	    fun getword s = StringCvt.splitl Char.isAlpha getc s

	    fun expect c s f =
		case getc s of
		    NONE => NONE
		  | SOME (c', s') => if c = c' then f s' else NONE

	    fun getdig s =
		case getc s of
		    NONE => NONE
		  | SOME (c, s') =>
		      if Char.isDigit c then
			  SOME (Char.ord c - Char.ord #"0", s')
		      else NONE

	    fun get2dig s =
		case getdig s of
		    SOME (c1, s') =>
		      (case getdig s' of
			   SOME (c2, s'') => SOME (10 * c1 + c2, s'')
			 | NONE => NONE)
		  | NONE => NONE

	    fun year0 (wday, mon, d, hr, mn, sc) s =
		case IntImp.scan StringCvt.DEC getc s of
		    NONE => NONE
		  | SOME (yr, s') =>
		      (SOME (date { year = yr,
				    month = mon,
				    day = d, hour = hr,
				    minute = mn, second = sc,
				    offset = NONE },
			     s')
		       handle _ => NONE)

	    fun year args s = expect #" " s (year0 args)

	    fun second0 (wday, mon, d, hr, mn) s =
		case get2dig s of
		    NONE => NONE
		  | SOME (sc, s') => year (wday, mon, d, hr, mn, sc) s'

	    fun second args s = expect #":" s (second0 args)

	    fun minute0 (wday, mon, d, hr) s =
		case get2dig s of
		    NONE => NONE
		  | SOME (mn, s') => second (wday, mon, d, hr, mn) s'

	    fun minute args s = expect #":" s (minute0 args)

	    fun time0 (wday, mon, d) s =
		case get2dig s of
		    NONE => NONE
		  | SOME (hr, s') => minute (wday, mon, d, hr) s'

	    fun time args s = expect #" " s (time0 args)

	    fun mday0 (wday, mon) s =
		case get2dig s of
		    NONE => NONE
		  | SOME (d, s') => time (wday, mon, d) s'

	    fun mday args s = expect #" " s (mday0 args)

	    fun month0 wday s =
		case getword s of
		    ("Jan", s') => mday (wday, Jan) s'
		  | ("Feb", s') => mday (wday, Feb) s'
		  | ("Mar", s') => mday (wday, Mar) s'
		  | ("Apr", s') => mday (wday, Apr) s'
		  | ("May", s') => mday (wday, May) s'
		  | ("Jun", s') => mday (wday, Jun) s'
		  | ("Jul", s') => mday (wday, Jul) s'
		  | ("Aug", s') => mday (wday, Aug) s'
		  | ("Sep", s') => mday (wday, Sep) s'
		  | ("Oct", s') => mday (wday, Oct) s'
		  | ("Nov", s') => mday (wday, Nov) s'
		  | ("Dec", s') => mday (wday, Dec) s'
		  | _ => NONE

	    fun month wday s = expect #" " s (month0 wday)

	    fun wday s =
		case getword s of
		    ("Sun", s') => month Sun s'
		  | ("Mon", s') => month Mon s'
		  | ("Tue", s') => month Tue s'
		  | ("Wed", s') => month Wed s'
		  | ("Thu", s') => month Thu s'
		  | ("Fri", s') => month Fri s'
		  | ("Sat", s') => month Sat s'
		  | _ => NONE
	in
	    wday s
	end

	fun fromString s = StringCvt.scanString scan s

	(* comparison does not take into account the offset
	 * thus, it does not compare dates in different time zones
	 *)
	fun compare (d1, d2) = let
	    fun list (DATE { year, month, day, hour, minute, second, ... }) =
		[year, monthToInt month, day, hour, minute, second]
	in
	    List.collate Int.compare (list d1, list d2)
	end
      
  end
end
