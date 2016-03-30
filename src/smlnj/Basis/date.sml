infix 7 * / div mod
infix 6 + - ^
infixr 5 :: @
infix 4 = <> > >= < <=
infix 3 := o

val op + = SMLSharp_Builtin.Int32.add_unsafe
val op - = SMLSharp_Builtin.Int32.sub_unsafe
val op * = SMLSharp_Builtin.Int32.mul_unsafe
val op mod = IntInf.mod
val op > = SMLSharp_Builtin.Int32.gt
val op < = SMLSharp_Builtin.Int32.lt
val op >= = SMLSharp_Builtin.Int32.gteq
structure Int = Int32
structure Word = Word32

(* date.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 *)

local
  structure Int = Int
  structure Int32 = Int32
  structure Time = Time
  structure SS = Substring
  structure String = String
in
structure Date =
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
    val dayTbl = [Sun, Mon, Tue, Wed, Thu, Fri, Sat]
    val monthTbl = [Jan, Feb, Mar, Apr, May, Jun, Jul, 
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
      | monthToInt Dec = 11

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
    fun ascTime tm =
        let
          val ascTime' = _import "asctime"
                         : __attribute__((fast)) tm -> char ptr
          val str = SMLSharp_Runtime.str_new (ascTime' tm)
        in
          String.substring (str, 0, (String.size str) - 1)
        end
    fun localTime' time =
        let
          val buf = Array.array (9, 0)
          (* FIXME: time_t can be 32-bit or 64-bit integer. *)
          val prim_localtime = _import "prim_Date_localTime"
                               : __attribute__((fast)) 
                                 (Int32.int, int array) -> int
          val retval = prim_localtime (time, buf)
          val _ = case retval of 0 => () 
                               | _ => raise SMLSharp_Runtime.OS_SysErr ()
        in
          (Array.sub (buf, 0),
           Array.sub (buf, 1),
           Array.sub (buf, 2),
           Array.sub (buf, 3),
           Array.sub (buf, 4),
           Array.sub (buf, 5),
           Array.sub (buf, 6),
           Array.sub (buf, 7),
           Array.sub (buf, 8))
        end
    fun gmTime' time =
        let
          val buf = Array.array (9, 0)
          val prim_gmtime = _import "prim_Date_gmTime"
                               : __attribute__((fast)) 
                                 (Int32.int, int array) -> int
          val retval = prim_gmtime (time, buf)
          val _ = case retval of 0 => () 
                               | _ => raise SMLSharp_Runtime.OS_SysErr ()
        in
          (Array.sub (buf, 0),
           Array.sub (buf, 1),
           Array.sub (buf, 2),
           Array.sub (buf, 3),
           Array.sub (buf, 4),
           Array.sub (buf, 5),
           Array.sub (buf, 6),
           Array.sub (buf, 7),
           Array.sub (buf, 8))
        end
    val mkTime' = _import "prim_Date_mkTime"
                  : __attribute__((fast)) tm -> Int32.int

    fun strfTime (format, tm) =
        let
          val strfTime' = _import "prim_Date_strfTime"
                          : __attribute__((fast))
                            (char array, word, string, tm) -> word
          (* FIXME: buffer size should not fix to 512. *)
          val buf = CharArray.array (512, #"\000")
          val len = strfTime' (buf, 0w512, format, tm)
          val _ = if len = 0w0 then raise SMLSharp_Runtime.OS_SysErr () else ()
        in
          CharArraySlice.vector 
            (CharArraySlice.slice (buf, 0, SOME (Word.toInt len)))
        end

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
	  (#1 tm2, #2 tm2, #3 tm2, #4 tm2, #5 tm2, #6 tm2, #7 tm2, #8 tm2, dst)

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
	fun wday abs = List.nth (dayTbl, Int.mod(abs,7))
	fun yday (year, abs) = let
	      val daysPrior = 
		  365 * (year -1)
		  + quot (year-1,4)
		  - quot (year-1,100)
		  + quot (year-1,400)
	      in 
		abs - daysPrior - 1    (* to conform to ISO standard *)
	      end
    end (* local *)

  (*
   * this function should also canonicalize the time (hours, etc...)
   *)
    fun canonicalizeDate (DATE d) = let
	  val args = (monthToInt(#month d), #day d, #year d)
	  val abs = toAbsolute args
	  val (monthC,dayC, yearC) = fromAbsolute abs
	  val yday = yday (yearC, abs)
	  val wday = wday abs
	  in
	    DATE{
		year = yearC,
		month = List.nth (monthTbl,monthC),
		day = dayC,
		hour = #hour d,
		minute = #minute d,
		second = #second d,
		offset = #offset d,
		isDst = NONE,
		yday = yday,
		wday = wday
	      }
	  end

    fun toTM d = let
	  val (DATE d) = canonicalizeDate d
	  in (
	    #second d,			(* tm_sec *)
	    #minute d,			(* tm_min *)
	    #hour d,			(* tm_hour *)
	    #day d,			(* tm_mday *)
	    monthToInt(#month d),	(* tm_mon *)
	    #year d - baseYear,		(* tm_year *)
	    dayToInt(#wday d),		(* tm_wday *)
	    #yday d,			(* tm_yday *)
	    case (#isDst d)		(* tm_isdst *)
	     of NONE => ~1
	      | (SOME false) => 0
	      | (SOME true) => 1
	    (* end case *)
	  ) end

    fun fromTM (tm_sec, tm_min, tm_hour, tm_mday, tm_mon,
		tm_year, tm_wday, tm_yday, tm_isdst) offset =
	  DATE{
	      year = baseYear + tm_year,
	      month = List.nth (monthTbl, tm_mon),
	      day = tm_mday,
	      hour = tm_hour,
	      minute = tm_min,
	      second = tm_sec,
	      wday = List.nth (dayTbl, tm_wday),
	      yday = tm_yday,
	      isDst = if (tm_isdst < 0) then NONE else SOME(tm_isdst <> 0),
	      offset = offset
	    }


    fun fromTimeLocal t = fromTM (localTime t) NONE

    fun fromTimeUniv t = fromTM (gmTime t) (SOME Time.zeroTime)

    fun fromTimeOffset (t, offset) =
	  fromTM (gmTime (Time.- (t, offset))) (SOME offset)

    val day_seconds = IntInf.fromInt (24 * 60 * 60)
    val hday_seconds = IntInf.fromInt (12 * 60 * 60)

    fun canonicalOffset off = let
          val op > = IntInf.>
          val op - = IntInf.-
	  val offs = Time.toSeconds off
	  val offs' = offs mod day_seconds
	  val offs'' = if offs' > hday_seconds then offs' - day_seconds else offs'
	  in
	    Time.fromSeconds offs''
	  end

    fun toTime d = let
	  val tm = toTM d
	  in
	    case offset d
	     of NONE => mkTime tm
	      | SOME tm_utc_off => let
		    val tm_utc_off = canonicalOffset tm_utc_off
		    val (loc_utc_off, loc_dst) = localOffset' ()
		    (* time west of here *)
		    val tm_loc_off = Time.- (tm_utc_off, loc_utc_off)
		in
		    (* pretend tm refers to local time, then subtract
		     * difference between dest. and local time *)
		    Time.+ (mkTime (withDst loc_dst tm), tm_loc_off)
		end
	  end

    fun date { year, month, day, hour, minute, second, offset } = let
	  val d = DATE{
		  second = second,
		  minute = minute,
		  hour = hour,
		  year = year,
		  month = month, 
		  day = day,
		  offset = offset,
		  isDst = NONE,
		  yday = 0,
		  wday = Mon
		}
	  val canonicalDate = canonicalizeDate d
	  fun internalDate () = (case offset
		 of NONE => fromTimeLocal (toTime canonicalDate)
		  | SOME off => fromTimeOffset (toTime canonicalDate, off)
		(* end case *))
	  in
	    internalDate () handle Date => d
	  end

    fun toString d = ascTime (toTM d)

  (* the size of the runtime system character buffer, not including space for the '\0' *)
    val fmtBuf = 512-1
    fun fmt fmtStr = let
	(* get a format character; the next character in start should be #"%" (or else
	 * start is empty.  Returns a triple (maxLen, frag, rest), where maxLen is an
	 * upperbound on the expansion of the format string, frag is the format string
	 * and rest is the rest of the substring.
	 *)
	  fun getFmtC start = (case SS.getc start
		 of SOME(_, rest) => let
		      fun continue (len, ss') = (len, SS.slice(start, 0, SOME 2), ss')
		      in
			case SS.getc rest
			 of NONE => (1, SS.full "%", rest)
			  | SOME(#"a", ss') => continue(3, ss')
			  | SOME(#"A", ss') => continue(20, ss')
			  | SOME(#"b", ss') => continue(3, ss')
			  | SOME(#"B", ss') => continue(20, ss')
			  | SOME(#"c", ss') => continue(24, ss')
			  | SOME(#"d", ss') => continue(2, ss')
			  | SOME(#"H", ss') => continue(2, ss')
			  | SOME(#"I", ss') => continue(2, ss')
			  | SOME(#"j", ss') => continue(3, ss')
			  | SOME(#"m", ss') => continue(2, ss')
			  | SOME(#"M", ss') => continue(2, ss')
			  | SOME(#"p", ss') => continue(3, ss')
			  | SOME(#"S", ss') => continue(2, ss')
			  | SOME(#"U", ss') => continue(2, ss')
			  | SOME(#"w", ss') => continue(1, ss')
			  | SOME(#"W", ss') => continue(2, ss')
			  | SOME(#"x", ss') => continue(24, ss')
			  | SOME(#"X", ss') => continue(24, ss')
			  | SOME(#"y", ss') => continue(2, ss')
			  | SOME(#"Y", ss') => continue(4, ss')
			  | SOME(#"Z", ss') => continue(3, ss')
			  | SOME(c, ss') => (1, SS.full(String.str c), ss')
			(* end case *)
		      end
		  | NONE => (0, start, start)
		(* end case *))
	  fun mkFmtFn (frags, fmtFns) = if List.null frags
		then fmtFns
		else let
		  val s = SS.concat(List.rev frags)
		  in
		    (fn tm => strfTime(s, tm)) :: fmtFns
		  end
	  fun notPct #"%" = false | notPct _ = true
	  fun scan (ss, totLen, frags, fmtFns) = let
		val (ss1, ss2) = SS.splitl notPct ss
		val n = SS.size ss1
		val (totLen, frags, fmtFns) = if (n = 0)
			then (totLen, frags, fmtFns)
		      else if (totLen+n >= fmtBuf)
			then let
			  val fmtFns = mkFmtFn(frags, fmtFns)
			  val s = SS.string ss1
			  in
			    (0, [], (fn _ => s) :: fmtFns)
			  end
			else (totLen+n, ss1::frags, fmtFns)
		in
		  case getFmtC ss2
		   of (0, _, _) => List.rev(mkFmtFn (frags, fmtFns))
		    | (n, frag, rest) => if (totLen + n >= fmtBuf)
			then let
			  val fmtFns = mkFmtFn(frags, fmtFns)
			  in
			    scan (rest, n, [frag], fmtFns)
			  end
			else scan (rest, totLen+n, frag::frags, fmtFns)
		  (* end case *)
		end
	  val fmtFns = scan (SS.full fmtStr, 0, [], [])
	  in
	    fn d => let val tm = toTM d in String.concat(List.map (fn f => f tm) fmtFns) end
	  end

    fun scan getc s = let

          val s = SMLSharp_ScanChar.skipSpaces getc s

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
  
	(* day can be two digits or one digit preceded by a space *)
	  fun getday s =
	      case get2dig s
		of NONE => 
		     expect #" " s (fn s' => getdig s')
		 | (res as SOME (n, s')) => res

	  fun year0 (wday, mon, d, hr, mn, sc) s =
	      case Int.scan StringCvt.DEC getc s of
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
	      case getday s of
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
  
	  fun wday s = (case getword s
		 of ("Sun", s') => month Sun s'
		  | ("Mon", s') => month Mon s'
		  | ("Tue", s') => month Tue s'
		  | ("Wed", s') => month Wed s'
		  | ("Thu", s') => month Thu s'
		  | ("Fri", s') => month Fri s'
		  | ("Sat", s') => month Sat s'
		  | _ => NONE
		(* end case *))
	  in
	    wday s
	  end (* scan *)

    fun fromString s = StringCvt.scanString scan s

    (* comparison does not take into account the offset
     * thus, it does not compare dates in different time zones
     *)
    fun compare (d1, d2) = let
	  fun list (DATE{year, month, day, hour, minute, second, ...}) =
		[year, monthToInt month, day, hour, minute, second]
	  in
	    List.collate Int.compare (list d1, list d2)
	  end

  end (* Date *)
end (* local *)
